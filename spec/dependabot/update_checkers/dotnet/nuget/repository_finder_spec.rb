# frozen_string_literal: true

require "spec_helper"
require "dependabot/dependency"
require "dependabot/dependency_file"
require "dependabot/update_checkers/dotnet/nuget/repository_finder"

RSpec.describe Dependabot::UpdateCheckers::Dotnet::Nuget::RepositoryFinder do
  subject(:finder) do
    described_class.new(
      dependency: dependency,
      credentials: credentials,
      config_file: config_file
    )
  end
  let(:config_file) { nil }
  let(:credentials) do
    [{
      "type" => "git_source",
      "host" => "github.com",
      "username" => "x-access-token",
      "password" => "token"
    }]
  end
  let(:dependency) do
    Dependabot::Dependency.new(
      name: "Microsoft.Extensions.DependencyModel",
      version: "1.1.1",
      requirements: [{
        requirement: "1.1.1",
        file: "my.csproj",
        groups: [],
        source: nil
      }],
      package_manager: "nuget"
    )
  end

  describe "dependency_urls" do
    subject(:dependency_urls) { finder.dependency_urls }

    it "gets the right URL without making any requests" do
      expect(dependency_urls).to eq(
        [{
          repository_url:  "https://api.nuget.org/v3/index.json",
          versions_url:    "https://api.nuget.org/v3-flatcontainer/"\
                           "microsoft.extensions.dependencymodel/index.json",
          search_url:      "https://api-v2v3search-0.nuget.org/query"\
                           "?q=microsoft.extensions.dependencymodel"\
                           "&prerelease=true",
          auth_header:     {},
          repository_type: "v3"
        }]
      )
    end

    context "with a URL passed as a credential" do
      let(:custom_repo_url) do
        "https://www.myget.org/F/exceptionless/api/v3/index.json"
      end
      let(:credentials) do
        [
          {
            "type" => "git_source",
            "host" => "github.com",
            "username" => "x-access-token",
            "password" => "token"
          },
          {
            "type" => "nuget_feed",
            "url" => custom_repo_url,
            "token" => "my:passw0rd"
          }
        ]
      end

      before do
        stub_request(:get, custom_repo_url).
          with(basic_auth: %w(my passw0rd)).
          to_return(
            status: 200,
            body: fixture("dotnet", "nuget_responses", "myget_base.json")
          )
      end

      it "gets the right URL" do
        expect(dependency_urls).to eq(
          [{
            repository_url:  "https://www.myget.org/F/exceptionless/api/v3/"\
                             "index.json",
            versions_url:    "https://www.myget.org/F/exceptionless/api/v3/"\
                             "flatcontainer/microsoft.extensions."\
                             "dependencymodel/index.json",
            search_url:      "https://www.myget.org/F/exceptionless/api/v3/"\
                             "query?q=microsoft.extensions.dependencymodel"\
                             "&prerelease=true",
            auth_header:     { "Authorization" => "Basic bXk6cGFzc3cwcmQ=" },
            repository_type: "v3"
          }]
        )
      end

      context "that 404s" do
        before { stub_request(:get, custom_repo_url).to_return(status: 404) }

        # TODO: Might want to raise here instead?
        it { is_expected.to eq([]) }
      end

      context "that 403s" do
        before { stub_request(:get, custom_repo_url).to_return(status: 403) }

        it "raises a useful error" do
          error_class = Dependabot::PrivateSourceAuthenticationFailure
          expect { finder.dependency_urls }.
            to raise_error do |error|
              expect(error).to be_a(error_class)
              expect(error.source).to eq(custom_repo_url)
            end
        end
      end

      context "without a token" do
        let(:credentials) do
          [{
            "type" => "git_source",
            "host" => "github.com",
            "username" => "x-access-token",
            "password" => "token"
          }, {
            "type" => "nuget_feed",
            "url" => custom_repo_url
          }]
        end

        before do
          stub_request(:get, custom_repo_url).
            with(basic_auth: nil).
            to_return(
              status: 200,
              body: fixture("dotnet", "nuget_responses", "myget_base.json")
            )
        end

        it "gets the right URL" do
          expect(dependency_urls).to eq(
            [{
              repository_url:  "https://www.myget.org/F/exceptionless/api/v3/"\
                               "index.json",
              versions_url:    "https://www.myget.org/F/exceptionless/api/v3/"\
                               "flatcontainer/microsoft.extensions."\
                               "dependencymodel/index.json",
              search_url:      "https://www.myget.org/F/exceptionless/api/v3/"\
                               "query?q=microsoft.extensions.dependencymodel"\
                               "&prerelease=true",
              auth_header:     {},
              repository_type: "v3"
            }]
          )
        end
      end
    end

    context "with a URL included in the nuget.config" do
      let(:config_file) do
        Dependabot::DependencyFile.new(
          name: "NuGet.Config",
          content: fixture("dotnet", "configs", "nuget.config")
        )
      end

      before do
        repo_url = "https://www.myget.org/F/exceptionless/api/v3/index.json"
        stub_request(:get, repo_url).to_return(status: 404)
        stub_request(:get, repo_url).
          with(basic_auth: %w(my passw0rd)).
          to_return(
            status: 200,
            body: fixture("dotnet", "nuget_responses", "myget_base.json")
          )
      end

      it "gets the right URLs" do
        expect(dependency_urls).to match_array(
          [
            {
              repository_url: "https://api.nuget.org/v3/index.json",
              versions_url:   "https://api.nuget.org/v3-flatcontainer/"\
                              "microsoft.extensions.dependencymodel/index.json",
              search_url:     "https://api-v2v3search-0.nuget.org/query"\
                              "?q=microsoft.extensions.dependencymodel"\
                              "&prerelease=true",
              auth_header:    {},
              repository_type: "v3"
            },
            {
              repository_url: "https://www.myget.org/F/exceptionless/api/v3/"\
                              "index.json",
              versions_url:   "https://www.myget.org/F/exceptionless/api/v3/"\
                              "flatcontainer/microsoft.extensions."\
                              "dependencymodel/index.json",
              search_url:     "https://www.myget.org/F/exceptionless/api/v3/"\
                              "query?q=microsoft.extensions.dependencymodel"\
                              "&prerelease=true",
              auth_header:    { "Authorization" => "Basic bXk6cGFzc3cwcmQ=" },
              repository_type: "v3"
            }
          ]
        )
      end

      context "that has a numeric key" do
        let(:config_file) do
          Dependabot::DependencyFile.new(
            name: "NuGet.Config",
            content: fixture("dotnet", "configs", "numeric_key.config")
          )
        end

        before do
          repo_url = "https://www.myget.org/F/exceptionless/api/v3/index.json"
          stub_request(:get, repo_url).
            to_return(
              status: 200,
              body: fixture("dotnet", "nuget_responses", "myget_base.json")
            )
        end

        it "gets the right URLs" do
          expect(dependency_urls).to match_array(
            [{
              repository_url: "https://www.myget.org/F/exceptionless/api/v3/"\
                              "index.json",
              versions_url:   "https://www.myget.org/F/exceptionless/api/v3/"\
                              "flatcontainer/microsoft.extensions."\
                              "dependencymodel/index.json",
              search_url:     "https://www.myget.org/F/exceptionless/api/v3/"\
                              "query?q=microsoft.extensions.dependencymodel"\
                              "&prerelease=true",
              auth_header:    {},
              repository_type: "v3"
            }]
          )
        end
      end

      context "that uses the v2 API alongside the v3 API" do
        let(:config_file) do
          Dependabot::DependencyFile.new(
            name: "NuGet.Config",
            content: fixture("dotnet", "configs", "with_v2_endpoints.config")
          )
        end

        before do
          v2_repo_urls = %w(
            https://www.nuget.org/api/v2/
            https://www.myget.org/F/azure-appservice/api/v2
            https://www.myget.org/F/azure-appservice-staging/api/v2
            https://www.myget.org/F/fusemandistfeed/api/v2
            https://www.myget.org/F/30de4ee06dd54956a82013fa17a3accb/
          )

          v2_repo_urls.each do |repo_url|
            stub_request(:get, repo_url).
              to_return(
                status: 200,
                body: fixture("dotnet", "nuget_responses", "v2_base.xml")
              )
          end

          url = "https://dotnet.myget.org/F/aspnetcore-dev/api/v3/index.json"
          stub_request(:get, url).
            to_return(
              status: 200,
              body: fixture("dotnet", "nuget_responses", "myget_base.json")
            )
        end

        it "gets the right URLs" do
          expect(dependency_urls).to match_array(
            [{
              repository_url:
                "https://dotnet.myget.org/F/aspnetcore-dev/api/v3/index.json",
              versions_url:
                "https://www.myget.org/F/exceptionless/api/v3/" \
                "flatcontainer/microsoft.extensions.dependencymodel/index.json",
              search_url:
                "https://www.myget.org/F/exceptionless/api/v3/"\
                "query?q=microsoft.extensions.dependencymodel&prerelease=true",
              auth_header: {},
              repository_type: "v3"
            }, {
              repository_url: "https://www.nuget.org/api/v2",
              versions_url:
                "https://www.nuget.org/api/v2/FindPackagesById()?id="\
                "'Microsoft.Extensions.DependencyModel'",
              auth_header: {},
              repository_type: "v2"
            }]
          )
        end
      end
    end
  end
end
