require 'puppet/provider/package'

Puppet::Type.type(:mysql_user).provide(:debian,
		:parent => Puppet::Provider::Package) do

	desc "Use mysql as database."
	optional_commands :mysql => '/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf'
	optional_commands :mysqladmin => '/usr/bin/mysqladmin --defaults-file=/etc/mysql/debian.cnf'

	defaultfor :operatingsystem => :debian

	def self.query_line_to_hash(line)
		fields = line.chomp.split(/\t/)
		{
			:name => fields[0],
			:password_hash => fields[1],
			:ensure => :present
		}
	end

	def self.instances
		users = []

		cmd = "#{command(:mysql)} mysql -NBe 'select concat(user, \"@\", host), password from user'"
		begin
			execpipe(cmd) do |process|
				process.each { |line|
					users << new(query_line_to_hash(line))
				}
			end
		rescue
			return users
		else
			return users
		end
	end

	def mysql_flush 
		mysqladmin munge_args("flush-privileges")
	end

	def query
		result = {}

		cmd = ( [ command(:mysql) ] + munge_args("mysql", "-NBe", "'select concat(user, \"@\", host), password from user where concat(user, \"@\", host) = \"%s\"'" % @resource[:name]) ).join(" ")
		execpipe(cmd) do |process|
			process.each do |line|
				unless result.empty?
					raise Puppet::Error,
						"Got multiple results for user '%s'" % @resource[:name]
				end
				result = query_line_to_hash(line)
			end
		end
		result
	end

	def create
		mysql munge_args("mysql", "-e", "create user '%s' identified by PASSWORD '%s'" % [ @resource[:name].sub("@", "'@'"), @resource.should(:password_hash) ])
		mysql_flush
	end

	def destroy
		mysql munge_args("mysql", "-e", "drop user '%s'" % @resource[:name].sub("@", "'@'"))
		mysql_flush
	end

	def exists?
		not mysql("mysql", "-NBe", "select '1' from user where CONCAT(user, '@', host) = '%s'" % @resource[:name]).empty?
	end

	def password_hash
		@property_hash[:password_hash]
	end

	def password_hash=(string)
		mysql "mysql", "-e", "SET PASSWORD FOR '%s' = '%s'" % [ @resource[:name].sub("@", "'@'"), string ]
		mysql_flush
	end
end

