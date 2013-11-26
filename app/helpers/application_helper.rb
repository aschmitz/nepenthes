module ApplicationHelper
  def tag_escape(input)
    # % / ? &
    input.gsub('%', '%25').gsub('/', '%2F').gsub('?', '%3F').gsub('&', '%26').gsub('.', '%2E')
  end
end
