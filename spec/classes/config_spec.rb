require 'spec_helper'

describe 'hitch::config' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "hitch::config class with parameters" do
          let(:params) do
            {
              config_root: "/etc/hatch",
              config_file: "/etc/hatch/hatch.conf",
              dhparams_file: "/etc/hatch/dhfarams.pem",
              domains: {}
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/hatch') }
          it { is_expected.to contain_file('/etc/hatch/dhfarams.pem') }
          it { is_expected.to contain_concat('/etc/hatch/hatch.conf') }
        end

        context "hitch::config class with domains" do
          let(:params) do
            {
              config_root: "/etc/hitch",
              config_file: "/etc/hitch/hitch.conf",
              dhparams_file: "/etc/hitch/dhparams.pem",
              :domains => {
                'example.com' => {
                  'key_content' => '-----BEGIN PRIVATE KEY-----',
                  'cert_content' => '-----BEGIN CERTIFICATE-----',
                  'cacert_content' => '-----BEGIN CERTIFICATE-----',
                  'dhparams_content' => '-----BEGIN DH PARAMETERS-----'
                }
              }
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_hitch__domain('example.com') }
          it { is_expected.to contain_file('/etc/hitch/example.com.pem') }
          it { is_expected.to contain_concat__fragment('hitch::domain example.com') }
          it { is_expected.to contain_concat__fragment('hitch::config config').without_content(/write-proxy-v2 = "off"/) }
        end

        context "hitch::config class with write_proxy_v2" do
          let(:params) do
            {
              config_root: "/etc/hitch",
              config_file: "/etc/hitch/hitch.conf",
              dhparams_file: "/etc/hitch/dhparams.pem",
              write_proxy_v2: "on",
              :domains => {}
            }
          end
          it { is_expected.to contain_concat__fragment('hitch::config config').with_content(/write-proxy-v2 = "on"/) }
        end
      end
    end
  end
end