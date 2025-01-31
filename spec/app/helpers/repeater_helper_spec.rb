require 'rails_helper'

RSpec.describe RepeaterHelper do
  let(:region) { 'us-east-1' }
  let(:user_id) { 1 }
  let(:group_id) { 1 }
  let(:sub_group_id) { 1 }
  let(:product) { 'automate' }
  let(:local_tunnel_info) do
    double(
      'local_tunnel_info',
      ats_local?: false,
      integrations_service_local?: false,
      backup_repeaters_address: nil,
      local_identifier: local_identifier,
      backup_repeaters_address: nil
    )
  end
  let(:local_identifier) { 'local-ip-geolocation-123' }
  let(:redis_utils)      { double("RedisUtils") }
  let(:region_restriction_utils)      { double("RegionRestrictionUtils") }
  let(:local_hub_repeater_regions)      { double("LocalHubRepeaterRegions") }
  let(:util) { double("Util") } 

  before do
    stub_const("RedisUtils", redis_utils)
    stub_const("RegionRestrictionUtils", region_restriction_utils)
    stub_const("LocalHubRepeaterRegions", local_hub_repeater_regions)
    stub_const("CONFIG", { env: { 'name' => 'test' } }) 
    stub_const("Util", util)

    allow(redis_utils).to receive(:allot_custom_repeaters?).and_return(false)
    allow(redis_utils).to receive(:region_blocked?).and_return(false)
    allow(redis_utils).to receive(:repeater_blocked?).and_return(false)
    allow(redis_utils).to receive(:get_custom_repeaters).and_return([])
    allow(RepeaterHelper).to receive(:get_custom_repeaters).and_return([[], []])
    allow(RepeaterHelper).to receive(:get_repeater_region).and_return([[], []])
    allow(RepeaterHelper).to receive(:get_ats_repeaters).and_return([[], []])
    allow(region_restriction_utils).to receive(:check_georestricted_group).and_return(false)
    allow(local_hub_repeater_regions).to receive(:get_repeater_hub_regions_for_user).and_return(nil)
    allow(local_tunnel_info).to receive(:backup_repeaters_address=).with(any_args)
    allow(Rails.logger).to receive(:info)
    allow(util).to receive(:send_to_pager)
  end

  describe '#get_repeater_list' do
    context 'when custom repeaters are allotted' do
      before do
        allow(redis_utils).to receive(:allot_custom_repeaters?).and_return(true)
      end
    
      context 'and local geolocation is enabled' do
        before do
          allow(local_identifier).to receive(:blank?).and_return(false)
          allow(local_identifier).to receive(:start_with?).with('local-ip-geolocation-').and_return(true)
        end
    
        it 'returns tunnel repeaters and backup map for the region' do
          expect(RepeaterHelper.get_repeater_list(region, nil, local_tunnel_info, user_id, group_id, sub_group_id, product)).to eq([[], []])
        end
      end
    
      context 'and local geolocation is not enabled' do
        before do
          allow(local_identifier).to receive(:blank?).and_return(true)
        end
    
        it 'returns tunnel repeaters and backup map' do
          expect(RepeaterHelper.get_repeater_list(region, nil, local_tunnel_info, user_id, group_id, sub_group_id, product)).to eq([[], []])
        end
      end
    end

    context 'when custom repeaters are not allotted' do
      before do
        allow(redis_utils).to receive(:allot_custom_repeaters?).and_return(false)
      end

      context 'and local tunnel info is ATS local' do
        before do
          allow(local_tunnel_info).to receive(:ats_local?).and_return(true)
        end

        it 'returns ATS repeaters and backup map' do
          expect(RepeaterHelper.get_repeater_list(region, nil, local_tunnel_info, user_id, group_id, sub_group_id, product)).to eq([[], []])
        end
      end

      context 'and local tunnel info is integrations service local' do
        before do
          allow(local_tunnel_info).to receive(:integrations_service_local?).and_return(true)
        end

        it 'returns ATS repeaters and backup map' do
          expect(RepeaterHelper.get_repeater_list(region, nil, local_tunnel_info, user_id, group_id, sub_group_id, product)).to eq([[], []])
        end
      end

      context 'and region is georestricted' do
        before do
          allow(region_restriction_utils).to receive(:check_georestricted_group).and_return(true)
        end

        it 'returns repeaters and backup map for the region' do
          expect(RepeaterHelper.get_repeater_list(region, nil, local_tunnel_info, user_id, group_id, sub_group_id, product)).to eq([[], []])
        end
      end

      context 'and local hub repeater regions are available' do
        let(:hub_repeater_sessions) { { 'us-west-1' => ['repeater1', 'repeater2'] }.to_json }
        let(:local_hub_repeater_regions_for_user) { double('local_hub_repeater_regions_for_user', hub_repeater_sessions: hub_repeater_sessions) }

        before do
          allow(local_hub_repeater_regions).to receive(:get_repeater_hub_regions_for_user).and_return(local_hub_repeater_regions_for_user)
        end

        it 'returns repeaters and backup map for the region and hub regions' do
          expect(RepeaterHelper.get_repeater_list(region, nil, local_tunnel_info, user_id, group_id, sub_group_id, product)).to eq([[], []])
        end
      end

      context 'and local hub repeater regions are not available' do
        before do
          allow(local_hub_repeater_regions).to receive(:get_repeater_hub_regions_for_user).and_return(nil)
        end

        it 'returns repeaters and backup map for the region' do
          expect(RepeaterHelper.get_repeater_list(region, nil, local_tunnel_info, user_id, group_id, sub_group_id, product)).to eq([[], []])
        end
      end
    end
  end

  describe '#get_ats_repeaters' do
    context 'when environment is production' do
      before do
        stub_const("CONFIG", { env: { 'name' => 'production' } }) 
        allow(Repeater).to receive(:where).and_return(double(select: []))
        allow(RepeaterHelper).to receive(:filter_damaged_repeaters).and_return([])
      end

      it 'returns ATS repeaters and backup map' do
        expect(RepeaterHelper.get_ats_repeaters(region)).to eq([[], []])
      end
    end

    context 'when environment is not production' do
      before do
        stub_const("CONFIG", { env: { 'name' => 'development' } }) 
      end

      it 'returns repeaters and backup map for the region' do
        expect(RepeaterHelper.get_ats_repeaters(region)).to eq([[], []])
      end
    end
  end

  describe '#get_repeater_region' do
    context 'when region is blocked' do
      before do
        allow(redis_utils).to receive(:region_blocked?).and_return(true)
        allow(redis_utils).to receive(:repeater_blocked?).and_return(true)
        allow(Repeater).to receive(:joins).and_return(double(where: double(where_not: double(select: []))))
        allow(RepeaterHelper).to receive(:filter_damaged_repeaters).and_return([])
      end

      it 'returns backup repeaters and backup map' do
        expect(RepeaterHelper.get_repeater_region(region)).to eq([[], []])
      end
    end

    context 'when region is not blocked' do
      before do
        allow(redis_utils).to receive(:region_blocked?).and_return(false)
        allow(redis_utils).to receive(:repeater_blocked?).and_return(false)
        allow(Repeater).to receive(:joins).and_return(double(where: double(where_not: double(select: []))))
        allow(RepeaterHelper).to receive(:filter_damaged_repeaters).and_return([])
      end

      it 'returns repeaters and backup map for the region' do
        expect(RepeaterHelper.get_repeater_region(region)).to eq([[], []])
      end
    end
  end

  describe '#get_custom_repeaters' do
    before do
      allow(CustomRepeaterAllocation).to receive(:joins).and_return(double(where: double(where_not: double(select: []))))
      allow(RepeaterHelper).to receive(:filter_damaged_repeaters).and_return([])
      allow(Rails.logger).to receive(:info)
      allow(Util).to receive(:send_to_pager)
    end

    it 'returns custom repeaters and backup repeaters' do
      expect(RepeaterHelper.get_custom_repeaters(user_id, group_id, sub_group_id, region)).to eq([[], []])
    end
  end

  describe '#filter_damaged_repeaters' do
    let(:up_repeaters) { [double('repeater', state: 'up')] }
    let(:partial_blacklisted_repeaters) { [double('repeater', state: 'partially_blacklisted')] }
    let(:down_repeaters) { [double('repeater', state: 'down')] }

    context 'when there are up repeaters' do
      it 'returns up repeaters' do
        expect(RepeaterHelper.filter_damaged_repeaters(up_repeaters + partial_blacklisted_repeaters + down_repeaters)).to eq(up_repeaters)
      end
    end

    context 'when there are no up repeaters but partially blacklisted repeaters' do
      it 'returns partially blacklisted repeaters' do
        expect(RepeaterHelper.filter_damaged_repeaters(partial_blacklisted_repeaters + down_repeaters)).to eq(partial_blacklisted_repeaters)
      end
    end

    context 'when all repeaters are down or blacklisted' do
      it 'returns an empty array' do
        expect(RepeaterHelper.filter_damaged_repeaters(down_repeaters)).to eq([])
      end
    end
  end
end