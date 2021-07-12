# frozen_string_literal: true

# == Schema Information
#
# Table name: verses
#
#  id             :integer          not null, primary key
#  chapter_id     :integer
#  verse_number   :integer
#  verse_index    :integer
#  verse_key      :string
#  text_madani    :text
#  text_indopak   :text
#  text_simple    :text
#  juz_number     :integer
#  hizb_number    :integer
#  rub_number     :integer
#  sajdah         :string
#  sajdah_number  :integer
#  page_number    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  image_url      :text
#  image_width    :integer
#  verse_root_id  :integer
#  verse_lemma_id :integer
#  verse_stem_id  :integer
#

class Verse < QuranCoreRecord
  include QuranSearchable

  belongs_to :chapter, inverse_of: :verses, counter_cache: true

  has_many :tafsirs
  has_many :words
  has_many :translations
  has_many :audio_files
  has_many :recitations, through: :audio_files

  # For eager loading
  has_one  :audio, class_name: 'AudioFile'

  attr_accessor :highlighted_text,
                :highlighted_translations

  def self.find_with_id_or_key(id)
    if(id.to_s.include?(':'))
      where(verse_key: id)
    else
      where(id: id)
    end.first
  end

  def self.filter_with_id_or_key(id)
    where(verse_key: id).or(where(id: id))
  end

  def highlighted_text
    @highlighted_text || text_uthmani
  end

  def verse_id
    id
  end

  def get_page_number(version)
    if :v1 == version
      page_number
    else
      v2_page
    end
  end

  def get_text(version)
    case version
    when :v1
      code_v1
    when :v2
      code_v2
    when :uthmani
      text_uthmani
    when :tajweed
      text_uthmani_tajweed.html_safe
    when :indopak
      text_indopak
    when :qpc_hafs
      qpc_uthmani_hafs
    end
  end
end
