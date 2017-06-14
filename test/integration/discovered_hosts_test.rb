require 'test_plugin_helper'
require 'integration_test_helper'

class DiscoveredHostsTest < IntegrationTestWithJavascript
  let(:discovered_host) { FactoryGirl.create(:discovered_host, :with_facts) }

  setup do
    discovered_host.save
    visit discovered_hosts_path
  end

  teardown do
    Host::Discovered.destroy_all
  end

  describe 'Reboot all' do
    let(:discovered_hosts) { Host::Discovered.all }

    test 'triggers reboot on all discovered_hosts' do
      Host::Discovered.any_instance
                      .expects(:reboot)
                      .at_least(discovered_hosts.count)
      select_all_hosts
      page.find_link('Reboot All').click
    end
  end

  describe 'can provision discovered_host' do
    setup do
      page.find_link('Provision').click
    end

    test 'and forwards to editing it' do
      create_host
      assert_equal edit_discovered_host_path(id: discovered_host),
                   current_path
    end

    context 'with a Hostgroup selected' do
      let(:discovery_hostgroup) { Hostgroup.first }

      test 'it passes it on' do
        select_from('host_hostgroup_id', discovery_hostgroup.name)
        create_host
        assert_equal discovery_hostgroup.id.to_s,
                     current_params['host']['hostgroup_id']
      end
    end

    context 'with a Location selected' do
      let(:discovery_location) { Location.first }

      test 'it passes it on' do
        select_from('host_location_id', discovery_location.name)
        create_host
        assert_equal discovery_location.id.to_s,
                     current_params['host']['location_id']
      end
    end

    context 'with a Organization selected' do
      let(:discovery_organization) { Organization.first }

      test 'it passes it on' do
        select_from('host_organization_id', discovery_organization.name)
        create_host
        assert_equal discovery_organization.id.to_s,
                     current_params['host']['organization_id']
      end
    end
  end

  private

  def select_all_hosts
    page.find('#check_all').click
  end

  def select_from(element_id, term = nil)
    if term
      page.find_by_id("s2id_#{element_id}").click
      page.find('.select2-input').send_keys(term)
    end
    page.find('.select2-results li:first-child').click
  end

  def create_host
    page.find("#fixedPropertiesSelector-#{discovered_host.id}")
        .find_button('Create Host').click
    wait_for_ajax
  end
end
