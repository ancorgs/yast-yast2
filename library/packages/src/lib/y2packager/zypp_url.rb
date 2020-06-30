# ------------------------------------------------------------------------------
# Copyright (c) 2017-2020 SUSE LLC, All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# ------------------------------------------------------------------------------

require "uri"
require "yast"
require "delegate"

module Y2Packager
  # This class represents a libzypp url, which doesn't really conform to rfc3986 
  #
  # The current implementation relies on SimpleDelegator to expose all the
  # methods of an underlying URI object, so it can be used as a direct
  # replacement in places that used to use URI, like {Y2Packager::Repository#raw_url}
  #
  # Some notes:
  # Variable substitution does not work in scheme, user or password
  # See https://doc.opensuse.org/projects/libzypp/HEAD/zypp-repovars.html
  # https://doc.opensuse.org/projects/libzypp/HEAD/structzypp_1_1repo_1_1RepoVarExpand.html
  class ZyppUrl < SimpleDelegator
    Yast.import "Pkg"

    # Repository schemes considered local (see #local?)
    # https://github.com/openSUSE/libzypp/blob/a7a038aeda1ad6d9e441e7d3755612aa83320dce/zypp/Url.cc#L458
    LOCAL_SCHEMES = [:cd, :dvd, :dir, :hd, :iso, :file].freeze

    # @param url [String, ZyppUrl, URI::Generic]
    def initialize(url)
      __setobj__(URI(repovars_escape(url.to_s)))
    end

    def uri
      __getobj__
    end

    alias_method :to_uri, :uri

    def to_s
      repovars_unescape(uri.to_s)
    end

    def hostname
      repovars_unescape(uri.hostname)
    end

    # TODO: escaping does not work here because the port wouldn't accept the
    # escaped characters either. We likely need to modify the regexp used by
    # URI to parse/validate the port
    def port
      repovars_unescape(uri.port)
    end

    def path
      repovars_unescape(uri.path)
    end

    # Not sure if the query part makes much sense in a zypper url
    def query
      repovars_unescape(uri.query)
    end

    # Determine if the URL is local
    #
    # @return [Boolean] true if the URL is considered local; false otherwise
    def local?
      LOCAL_SCHEMES.include?(scheme&.to_sym)
    end

    #
    # @see Yast::Pkg.SourceDelete
    # @see Yast::Pkg.SourceSaveAll
    def expanded
      ZyppUrl.new(Yast::Pkg.ExpandedUrl(to_s))
    end

    # String representation of the state of the object
    #
    # @return [String]
    def inspect
      # Prevent SimpleDelegator from forwarding this to the wrapped URI object
      "#<#{self.class}:#{object_id}} @uri=#{uri.inspect}>"
    end

    def ==(other)
      if other.is_a?(URI::Generic)
        uri == other
      elsif other.class == self.class
        uri == other.uri
      else
        false
      end
    end

    alias_method :eql?, :==

  private

    def repovars_escape(str)
      str.gsub("{", "%7B").gsub("}", "%7D")
    end

    def repovars_unescape(str)
      str.gsub("%7B", "{").gsub("%7D", "}")
    end
  end
end
