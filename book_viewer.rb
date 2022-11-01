require "tilt/erubis"
require "sinatra"
require "sinatra/reloader" if development?

before do
  @contents = File.readlines("data/toc.txt")
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  @title = @contents[number - 1]

  redirect "/" unless (1..@contents.size).cover?(number)
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

get "/search" do
  @title = "Search"
  @query = params[:query]
  @results = matching_chapters(@query)

  erb :search
end

not_found do
  redirect "/"
end

def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield(number, name, contents)
  end
end

def each_paragraph(text)
  text.split("\n\n").each_with_index do |paragraph, number|
    yield(paragraph, number)
  end
end

def matching_chapters(query)
  if query
    query = query.downcase
    results = []

    each_chapter do |number, name, contents|
      matching_paragraphs = []
      each_paragraph(contents) do |paragraph, p_number|
        matching_paragraphs << { number: p_number, text: paragraph } if paragraph.downcase.include?(query)
      end
      results << { number: number, name: name, paragraphs: matching_paragraphs } unless matching_paragraphs.empty?
    end
    results
  end
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").map.with_index { |para, ind| "<p id=p#{ind}>#{para}<p>" }.join
  end

  def emphasise(text, target)
    matching_text = Regexp.new(target, true).match(text).to_s
    text.gsub(matching_text, "<strong>#{matching_text}</strong>")
  end
end