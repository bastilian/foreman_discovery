require 'test_plugin_helper'
require 'integration_test_helper'

class DiscoveredHostsTest < IntegrationTestWithJavascript
  let(:discovered_host) { FactoryGirl.create(:discovered_host, :with_facts) }
  let(:discovered_hosts) { Host::Discovered.all }

  setup do
    discovered_host.save!
    visit discovered_hosts_path
  end

  teardown do
    Host::Discovered.destroy_all
  end

  describe 'Reboot all' do
    test 'triggers reboot on all discovered_hosts' do
      Host::Discovered.any_instance
                      .expects(:reboot)
                      .at_least(discovered_hosts.count)
      select_all_hosts
      page.find_link('Reboot All').click
    end
  end

  describe 'Autoprovision all' do
    test 'converts all discovered to managed hosts' do
      select_all_hosts
      page.find_link('Auto Provision All').click
      wait_for_ajax
      assert page.has_text?('Discovered hosts are provisioning now')
    end
  end

  describe 'Delete hosts' do
    test 'it removes all hosts' do
      select_all_hosts
      page.find_link('Select Action').click
      page.find_link('Delete hosts').click
      wait_for_ajax
      assert page.has_text?('The following hosts are about to be changed')
      page.find_button('Submit').click
      wait_for_ajax
      assert page.has_text?('Destroyed selected hosts')
    end
  end

  describe 'using Create Host link' do
    setup do
      page.find("#host_ids_#{discovered_host.id}")
          .query_scope
          .find_link('Provision').click
    end

    test 'and forwards to editing it' do
      create_host
      assert_equal edit_discovered_host_path(id: discovered_host),
                   current_path
    end

    context 'with a Hostgroup selected' do
      let(:discovery_hostgroup) { Hostgroup.first }

      test 'it passes it on' do
        select_from('host_hostgroup_id', discovery_hostgroup.id)
        create_host
        assert_param discovery_hostgroup.id.to_s,
                     'host.hostgroup_id'
      end
    end

    context 'with a Location selected' do
      let(:discovery_location) { Location.first }

      test 'it passes it on' do
        select_from('host_location_id', discovery_location.id)
        create_host
        assert_param discovery_location.id.to_s,
                     'host.location_id'
      end
    end

    context 'with a Organization selected' do
      let(:discovery_organization) { Organization.first }

      test 'it passes it on' do
        select_from('host_organization_id', discovery_organization.id)
        create_host
        assert_param discovery_organization.id.to_s,
                     'host.organization_id'
      end
    end
  end

  private

  def select_all_hosts
    page.find('#check_all').click
  end

  def select_from(element_id, id)
    page.find_by_id(element_id, visible: false)
        .find("option[value='#{id}']", visible: false)
        .select_option
  end

  def create_host
    page.find("#fixedPropertiesSelector-#{discovered_host.id}")
        .find_button('Create Host').click
    wait_for_ajax
  end
end
