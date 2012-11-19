module OVIRT
  class Client
    def storagedomain(sd_id)
      sd = http_get("/storagedomains/%s" % sd_id)
      OVIRT::StorageDomain::new(self, sd.root)
    end

    def storagedomains(opts={})
      xml_response = nil
      if filtered_api
        xml_response = http_get("/storagedomains")
      else
        search= opts[:search] || ("datacenter=%s" % current_datacenter.name)
        xml_response = http_get("/storagedomains?search=%s" % CGI.escape(search))
      end
      xml_response.xpath('/storage_domains/storage_domain').collect do |sd|
        storage_domain = OVIRT::StorageDomain::new(self, sd)
        #filter by role is not supported by the search language. The work around is to list all, then filter.
        (opts[:role].nil? || storage_domain.role == opts[:role]) ? storage_domain : nil
      end.compact
    end
  end
end
