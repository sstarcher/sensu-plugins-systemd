#! /usr/bin/env ruby
#
#   check-failed-units.rb
#
# DESCRIPTION:
# => Check if there are any failed systemd service units
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: systemd-bindings
#
# USAGE:

#
# LICENSE:
#   Bobby Martin <nyxcharon@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'systemd'

class CheckFailedUnits < Sensu::Plugin::Check::CLI
  option :ignoremasked,
         description: 'Ignore Masked Units',
         short: '-m',
         default: false

  option :ignore,
         description: 'Ignore Units',
         short: '-i',
         long: '--ignore SERVICE',
         proc: proc { |d| d.split(',') }

  def run
    begin
      systemd = Systemd::SystemdManager.new
    rescue
      unknown 'Can not connect to systemd'
    end

    failed_units = ''
    systemd.units.each do |unit|
      next unless unit.name.include?('.service') && unit.active_state.include?('failed')
      next if config[:ignoremasked] && unit.load_state.include?('masked')
      next if config[:ignore] && config[:ignore].include?(unit.name)
      failed_units += unit.name + ','
    end
    if failed_units.empty?
      ok 'No failed service units'
    else
      critical "Found failed service units: #{failed_units}"
    end
  end
end
