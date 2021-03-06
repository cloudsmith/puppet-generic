class libvirt {
	package {
		"libvirt-bin":
			ensure => installed;
		"libvirt-doc":
			ensure => installed;
		"netcat-openbsd":
			ensure => installed;
	}

	service {
		"libvirt-bin":
			hasrestart => true,
			hasstatus => true,
			require => Package["libvirt-bin"];
	}

	file {
		"/etc/libvirt/libvirtd.conf":
			source => "puppet://puppet/libvirt/libvirt/libvirtd.conf",
			owner => "root",
			group => "root",
			mode => 644,
			require => Package["libvirt-bin"],
			notify => Service["libvirt-bin"];
	}
}
