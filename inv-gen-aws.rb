require 'aws-sdk'

active_region = 'eu-west-1'

Aws.config.update({ region: active_region })

ec2 = Aws::EC2::Client.new

resp = ec2.describe_instances({ filters: [
                                           {name:"tag:environment",values:['cassandra']}
                                         ]})

inventory = []
bastion_ip = '?.?.?.?'

resp.reservations.each do |res|
  res.instances.select{ |x| x.state.name == 'running'}.each do |instance|
    inventory.push({ 
      'name' => instance.instance_id, 
      'role' => instance.tags.find{ |x| x.key.downcase == 'role'}.value,
      'rack' => instance.placement.availability_zone, 
      'ip' => (instance.public_ip_address || instance.private_ip_address),
      'seed' => instance.tags.find{ |x| x.key.downcase == 'seed'} != nil
      })
  end
end

puts '[bastion]'
inventory.each do |instance|
  if instance['role'] == 'bastion'
    puts "#{instance['name']} ansible_host=#{instance['ip']} ansible_user=ec2-user"
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
puts 'ansible_user=ec2-user'
puts "ansible_ssh_common_args='-o \"ProxyCommand ssh -A ec2-user@#{bastion_ip} -W %h:%p\"'"