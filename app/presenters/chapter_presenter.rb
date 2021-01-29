# frozen_string_literal: true

class ChapterPresenter < HomePresenter
  WORD_TEXT_TYPES = [
    'v1',
    'v2',
    'indopak',
    'uthmani',
    'imlaei'
  ].freeze

  FONT_METHODS = {
    'v1' => 'code',
    'v2' => 'code_v2',
    'uthmani' => 'text_uthmani',
    'imlaei' => 'text_imlaei',
    'indopak' => 'text_indopak',
    'tajweed' => 'text_uthmani_tajweed',
  }.freeze

  def initialize(context)
    super context

    @range_start, @range_end = params[:range].to_s.split(/-|:/)
  end

  def cache_key
    begin
      _start = verse_pagination_start
      _end = verse_pagination_end(_start, per_page)
    rescue Exception => e
      _start = 'buggy'
      _end = 'buggy'
    end

    "f:#{font_method}-ch:#{params[:id]}-r:#{reading_mode?}-tr:#{valid_translations.join('-')}-range:#{_start}-#{_end}"
  end

  def chapter
    strong_memoize :chapter do
      Chapter.find_using_slug(params[:id])
    end
  end

  def active_tab
    if reading_mode?
      'reading'
    else
      'translation'
    end
  end

  def reading_mode?
    strong_memoize :reading_mode do
      reading = params[:reading].presence
      @reading_mode = reading.to_s == 'true'
    end
  end

  def font
    strong_memoize :font do
      _font = params[:font].presence || session[:font] || 'v1'
      _font = FONT_METHODS.key?(_font) ? _font : 'v1'
      session[:font] = _font
    end
  end

  def font_method
    strong_memoize :font_method do
      _font = font
      if reading_mode? && 'tajweed' == _font
        # we don't have wbw data for tajweed, fallback to uthmani script
        _font = 'uthmani'
      end

      FONT_METHODS[_font].presence || 'code'
    end
  end

  def showing_qcf_font?
    ['code_v2', 'code'].include? font_method
  end

  def render_verse_words?
    strong_memoize :render_words do
      WORD_TEXT_TYPES.include?(font)
    end
  end

  def paginate
    strong_memoize :paginate do
      verses(verse_pagination_start, per_page)
    end
  end

  def all
    per = range_end - range_start
    verses(verse_pagination_start, per + 1)
  end

  def per_page
    10.0
  end

  # Next page number in the collection
  def next_page
    if last_page? || out_of_range?
      return nil
    end

    if reading_mode?
      return paginate.last.page_number + 1
    end

    current_page + 1
  end

  # Previous page number in the collection
  def prev_page
    current_page - 1 unless first_page? || out_of_range?
  end

  # First page of the collection?
  def first_page?
    current_page == 1
  end

  # Last page of the collection?
  def last_page?
    if reading_mode?
      paginate.last.verse_number >= range_end
    else
      current_page == total_pages
    end
  end

  # Out of range of the collection?
  def out_of_range?
    if reading_mode?
      paginate.last.nil? || paginate.last.verse_number > range_end
    else
      current_page > total_pages
    end
  end

  def range
    #"#{range_start}-#{range_end}"
    params[:range]
  end

  def current_page
    params[:page].to_i <= 1 ? 1 : params[:page].to_i
  end

  def total_pages
    total = (range_end - range_start) + 1

    (total / per_page).ceil
  end

  def has_more_verses?
    range_end < chapter.verses_count
  end

  def has_previous_verses?
    range_start > 1
  end

  def show_bismillah?
    single_ayah? || chapter.bismillah_pre?
  end

  def single_ayah?
    # 2/255-255
    # 2/10
    # /ayat-ul-kursi all are single ayah

    @range_start.present? && (@range_end.nil? || @range_end == @range_start)
  end

  def continue?
    if last = paginate.last
      last.verse_number < chapter.verses_count
    end
  end

  def continue_range
    context.range_path(@chapter, "#{range_start}-#{chapter.verses_count}", reading: reading_mode?)
  end

  def previous_surah?
    chapter.chapter_number - 1 if chapter.chapter_number > 1
  end

  def next_surah?
    chapter.chapter_number + 1 if chapter.chapter_number < 114
  end

  def params_for_verse_link
    strong_memoize :verse_link_params do
      if (translation = valid_translations).present?
        "?translations=#{translation.join(',')}"
      end
    end
  end

  def render_translations?
    strong_memoize :render_translation do
      valid_translations.present?
    end
  end

  def show_verse_actions?
    true
  end

  def meta_page_type
    'article'
  end

  def meta_keyword
    chapter.translated_names.pluck(:name) + ['القران الكريم',
                                             'القرآن',
                                             'قران',
                                             'quran']
  end

  def meta_description
    strong_memoize :meta_description do
      first_verse = paginate.first
      translation = first_verse.translations.first || first_verse.translations.find_by_resource_content_id(DEFAULT_TRANSLATION)

      "Surah #{chapter.name_simple}(#{chapter.name_arabic}) #{paginate.first.verse_key} #{sanitize_meta_description_text(translation.text)}"
    end
  end

  def meta_url
    first_verse = paginate.first

    translations = valid_translations

    query_hash = {}
    query_hash[:font] = params[:font]
    query_hash[:translations] = translations.join(',').presence
    query_hash.compact!

    query_string = query_hash.present? ? "?#{query_hash.to_query}" : ''

    "https://quran.com/#{first_verse.verse_key.sub(':', '/')}#{query_string}"
  end

  def meta_title
    "Surah #{chapter.name_simple} - #{paginate.first.verse_key}"
  end

  def meta_image
    #"https://exports.qurancdn.com/images/#{paginate.first.verse_key}.png?color=black&font=qcfv1&fontSize=50&translation=131"

    first = paginate.first
    "https://quran-og-image.vercel.app/#{first.verse_key.gsub(':', '/')}"
  end

  protected

  def verses(verse_start, per)
    return @verses if @verses

    verse_end = verse_pagination_end(verse_start, per)

    fetch_verses_range(verse_start, verse_end)
    load_translations
    load_words

    @results.order('verses.verse_index ASC, words.position ASC, word_translations.priority ASC')
  end

  def fetch_verses_range(verse_start, verse_end)
    @results = Verse
                 .where(chapter_id: chapter.id)
                 .where('verses.verse_number >= ? AND verses.verse_number <= ?', verse_start.to_i, verse_end.to_i)
  end

  def load_words
    words_with_default_translation = @results.where(word_translations: {language_id: Language.default.id})

    if (language.id != Language.default.id)
      @results = @results
                   .where(word_translations: {language_id: language.id})
                   .or(words_with_default_translation)
                   .eager_load(words: :word_translation)
    else
      @results = words_with_default_translation
                   .eager_load(words: :word_translation)
    end
  end

  def load_translations
    translations = valid_translations

    if translations.present?
      @results = @results
                   .where(translations: {resource_content_id: translations})
                   .eager_load(:translations)
                   .order('translations.priority ASC')
    end
  end

  def range_end
    if @range_start && @range_end.nil?
      # For single ayah(e.g 2/1) range start and end should be same. One ayah

      range_start
    else
      min((@range_end || chapter.verses_count).to_i, chapter.verses_count)
    end
  end

  def range_start
    start = (@range_start || 1).to_i

    min(start, chapter.verses_count)
  end

  def verse_pagination_start
    if reading_mode?
      # on reading more, we render one page each request
      # per_page is ignored
      first_verse = nil
      if params[:page]
        first_verse = Verse.where(chapter_id: chapter.id, page_number: params[:page]).first
      else
        first_verse = Verse.where(chapter_id: chapter.id).first
      end

      max(first_verse.verse_number, range_start)
    else
      (((current_page - 1) * per_page) + range_start).to_i
    end
  end

  def verse_pagination_end(start, per)
    if reading_mode?
      first = Verse.where(chapter_id: chapter.id, 'verses.verse_number': start).first
      last_on_page = Verse.where(chapter_id: chapter.id, page_number: first.page_number).last

      return min(last_on_page.verse_number, range_end)
    end

    min((start + per) - 1, range_end)
  end

  def min(a, b)
    a < b ? a : b
  end

  def max(a, b)
    a > b ? a : b
  end
end
