require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

before do
  @chapters = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(string)
    string.split("\n\n").each_with_index.map do |para, index|
      "<p id=para#{index}>#{para}</p>"
    end.join
  end

  def highlight(text, term)
    text.gsub(term, %(<strong>#{term}</strong>))
  end
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  redirect "/" unless (1..@chapters.size).cover? number

  @content = File.read("data/chp#{number}.txt")
  chapter_title = @chapters[number - 1]
  @title = "Chapter #{number}: #{chapter_title}"
  erb :chapter
end

not_found do
  redirect "/"
end

def each_chapter
  @chapters.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield(number, name, contents)
  end
end

def chapters_matching(query)
  results = []

  return results unless query

  each_chapter do |number, name, contents|
    matches = {}
    contents.split("\n\n").each_with_index do |para, index|
      matches[index] = para if para.include?(query)
    end
    results << {number: number, name: name, paragraphs: matches} if matches.any?
  end

  results
end


get "/search" do
  @results = chapters_matching(params[:query])
  erb :form
end