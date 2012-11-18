module OVIRT
  class Client
    def host(host_id, opts={})
      xml_response = http_get("/hosts/%s" % host_id)
      OVIRT::Host::new(self, xml_response.root)
    end

    def hosts(opts={})
      xml_response = nil
      if filtered_api
        xml_response = http_get("/hosts")
      else
        search= opts[:search] || ("datacenter=%s" % current_datacenter.name)
        xml_response = http_get("/hosts?search=%s" % CGI.escape(search))
      end
      xml_response.xpath('/hosts/host').collect do |h|
        OVIRT::Host::new(self, h)
      end
    end
  end
end
