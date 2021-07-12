# Image URLs
#
# # sample
# * https://imglf3.lf127.net/img/S1d2QlVsWkJhSW1qcnpIS0ZSa3ZJSzFCWFlnUWgzb01DcUdpT1lreG5yQjJVMkhGS09HNGR3PT0.png?imageView&thumbnail=1680x0&quality=96&stripmeta=0
#
# # full size
# * https://imglf3.lf127.net/img/S1d2QlVsWkJhSW1qcnpIS0ZSa3ZJSzFCWFlnUWgzb01DcUdpT1lreG5yQjJVMkhGS09HNGR3PT0.png
# * http://imglf0.nosdn.127.net/img/cHl3bXNZdDRaaHBnNWJuN1Y4OXBqR01CeVBZSVNmU2FWZWtHc1h4ZTZiUGxlRzMwZnFDM1JnPT0.jpg (404)
#
# Page URLs
#
# * https://gengar563.lofter.com/post/1e82da8c_1c98dae1b
# * https://yuli031458.lofter.com/post/3163d871_1cbdc5f6d (different theme/css selectors)
# * https://ssucrose.lofter.com/post/1d30f3e4_1cc58e9f0 (another different theme)
#
# Profile URLs
#
# * http://gengar563.lofter.com/

module Sources
  module Strategies
    class Lofter < Base
      PROFILE_URL = %r{\Ahttps?://(?<artist_name>[\w-]+).lofter.com}i
      PAGE_URL =    %r{#{PROFILE_URL}/post/(?<illust_id>[\w-]+)}i
      IMAGE_HOST =  %r{\Ahttps?://imglf\d\.(?:nosdn\d?\.12\d|lf127)\.net}i
      IMAGE_URL =   %r{#{IMAGE_HOST}/img/\w+\.\w+}i

      def domains
        ["lofter.com", "lf127.net"]
      end

      def site_name
        "Lofter"
      end

      def match?
        return false if parsed_url.nil?
        parsed_url.domain.in?(domains) || parsed_url.host =~ IMAGE_HOST
      end

      def image_url
        if url =~ IMAGE_URL
          get_full_version(url)
        else
          image_urls.first
        end
      end

      def image_urls
        images = page&.search(".imgclasstag img")
        images.to_a.map { |img| get_full_version(img["src"]) }
      end

      def get_full_version(url)
        parsed = URI.parse(url)
        "https://#{parsed.host}#{parsed.path}"
      end

      def profile_url
        return nil if artist_name.blank?
        "https://#{artist_name}.lofter.com"
      end

      def page_url
        return nil if illust_id.blank? || profile_url.blank?

        "#{profile_url}/post/#{illust_id}"
      end

      def page
        return nil if page_url.blank?

        response = http.cache(1.minute).get(page_url)
        response.parse if response.status == 200
      end

      def tags
        tags = page&.search(".info .tag, .main .tag a, .tagarea")

        tags.to_a.map do |tag|
          [tag.text, tag.attr("href")]
        end
      end

      def artist_commentary_desc
        page&.search(".ct .text, .content .text").to_a.compact.first&.to_html
      end

      def normalize_for_source
        page_url
      end

      def illust_id
        urls.map { |u| u[PAGE_URL, :illust_id] }.compact.first
      end

      def artist_name
        urls.map { |u| u[PROFILE_URL, :artist_name] || u[PAGE_URL, :artist_name] }.compact.first
      end
    end
  end
end
