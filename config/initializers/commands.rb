# http://stackoverflow.com/a/5471032
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each { |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable? exe
    }
  end
  return nil
end

$TIMEOUT_PATH = which 'timeout'
if $TIMEOUT_PATH == nil
  $TIMEOUT_PATH = which 'gtimeout'
end
$OPENSSL_PATH = which 'openssl'
$PHANTOMJS_PATH = which 'phantomjs'
$NIKTO_PATH = which 'nikto'
