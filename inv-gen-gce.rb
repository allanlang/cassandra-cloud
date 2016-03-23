require 'json'

active_region = 'europe-west1'
ssh_user = 'cassandra'

gce_data = `gcloud compute instances list --format json`
json_data = JSON.parse(gce_data)

inventory = []
bastion_ip = '?.?.?.?'

json_data.each do |instance|
  role = instance['metadata']['items'].find{ |x| x['key'].downcase == 'role'}
  extip = instance['networkInterfaces'][0]['accessConfigs']
  inventory.push({
    'name' => instance['name'], 
    'role' => (role != nil) ? role['value'] : 'none',
    'rack' => instance['zone'], 
    'ip' => (extip != nil) ? extip[0]['natIP'] : instance['networkInterfaces'][0]['networkIP'],
    'seed' => instance['tags']['items'].find{ |x| x == 'seed'} != nil
  })
end

puts '[bastion]'
inventory.each do |instance|
  if instance['role'] == 'bastion'
    puts "#{instance['name']} ansible_host=#{instance['ip']} ansible_user=#{ssh_user}"
    bastion_ip = instance['ip']
  end
end
puts ''
puts '[seeds]'
inventory.each do |instance|
  if instance['seed']
    puts "#{instance['name']} ansible_host=#{instance['ip']} data_center=#{active_region} rack=#{instance['rack']}"
  end
end
puts ''
puts '[nodes]'
inventory.each do |instance|
  if instance['role'] == 'cassandra-node' && !instance['seed']
    puts "#{instance['name']} ansible_host=#{instance['ip']} data_center=#{active_region} rack=#{instance['rack']}"
  end
end
puts ''
puts '[cassandra:children]'
puts 'seeds'
puts 'nodes'
puts ''
puts '[cassandra:vars]'
puts "ansible_user=#{ssh_user}"
puts "ansible_ssh_common_args='-o \"ProxyCommand ssh -A #{ssh_user}@#{bastion_ip} -W %h:%p\"'"