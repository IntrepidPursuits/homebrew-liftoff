require 'formula'

class Liftoff < Formula
  homepage 'https://github.com/IntrepidPursuits/homebrew-liftoff'
  url 'https://github.com/IntrepidPursuits/homebrew-liftoff/archive/__VERSION__.tar.gz'
  sha1 '__SHA__'

  depends_on 'xcproj' => :recommended
  depends_on 'jenkins_api_client' => :recommended

  def install
    prefix.install 'defaults', 'templates', 'vendor'
    prefix.install 'lib' => 'rubylib'

    man1.install ['man/liftoff.1']
    man5.install ['man/liftoffrc.5']

    bin.install 'src/liftoff'
  end

  test do
    system "#{bin}/liftoff", '--version'
  end
end
