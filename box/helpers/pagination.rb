module Box
  module Helpers
    module Pagination
      def setup_pagination_header(record_count)
        # Extract query params
        query_params = request.env['rack.request.query_hash']

        # Calculate total pages
        total_pages, remainder = record_count.divmod(params['per_page'])
        total_pages += 1 if remainder > 0

        # Build urls
        urls = {
          next: build_path('page' => params['page'] + 1),
          prev: build_path('page' => params['page'] - 1),
          first: build_path('page' => 1),
          last: build_path('page' => total_pages),
        }

        # Remove urls which do not make any sense to display
        if params['page'] >= total_pages
          urls.delete(:next) if params['page']
          urls.delete(:last) if params['page']
        end

        if params['page'] == 1
          urls.delete(:prev)
          urls.delete(:first)
        end

        # Set pagination header
        header "Link", urls.map { |rel, url| "<#{url}>; rel='#{rel}'" }.join(',')
      end

      def build_path(new_params)
        new_query = Rack::Utils.build_query(request.env['rack.request.query_hash'].merge(new_params))
        Rack::Request.new(request.env).url.split('?').first + '?' + new_query
      end
    end
  end
end
