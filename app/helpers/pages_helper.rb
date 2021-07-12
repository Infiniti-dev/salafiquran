# frozen_string_literal: true

module PagesHelper
  def group_verse_by_page_and_lines(verses)
    #  Group words by page then by line number,
    # and return words with following schema
    # lines = {
    #     page: [
    #         line: {
    #             verse_number: {
    #                 index: verse_index,
    #                 verse_number: verse_number,
    #                 words: [list, of, words]
    #             }
    #         }
    #     ]
    # }

    lines = {}
    index = 0

    verses.group_by(&:page_number).each do |page, page_verses|
      lines[page] = {
      }

      page_verses.each do |verse, i|
        verse.words.each do |w|
          lines[page][w.line_number] ||= {}

          lines[page][w.line_number][verse.verse_number] ||= {
            index: index,
            verse_number: verse.verse_number,
            words: []
          }

          lines[page][w.line_number][verse.verse_number][:words] << w
        end
        index += 1
      end
    end

    lines
  end

  def group_words_lines(verses, mushaf_type)
    lines = {}

    verses.each do |verse|
      verse.words.each do |w|
        line_number = w.get_line_number(mushaf_type)
        lines[line_number] ||= {}
        lines[line_number][w.verse_id] ||= []

        lines[line_number][w.verse_id] << w
      end
    end

    lines
  end
end
