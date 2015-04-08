# Via http://stackoverflow.com/a/23138291

module I18nHelper
  def translate(key, options={})
    super(key, options.merge(raise: true))
  rescue I18n::MissingTranslationData
    key
  end
  alias :t :translate
end
