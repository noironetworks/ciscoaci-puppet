Name:           ciscoaci-puppet
Version:        14.0
Release:        %{?release}%{!?release:1}
Summary:        Puppet manifests for configuring Cisco Aci Openstack plugin
License:        ASL 2.0
Group:          Applications/Utilities
Source0:        ciscoaci-puppet.tar.gz
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       puppet

%define installPath /usr/share/openstack-puppet/modules/

%define debug_package %{nil}

%description
This package contains ciscoaci puppet module

%prep
%setup -q -n ciscoaci-puppet

%install
rm -rf $RPM_BUILD_ROOT/usr/share/openstack-puppet/modules
mkdir -p $RPM_BUILD_ROOT/usr/share/openstack-puppet/modules
cp -r ciscoaci $RPM_BUILD_ROOT/usr/share/openstack-puppet/modules

rm -rf $RPM_BUILD_ROOT/usr/share/openstack-puppet/modules/tripleo/manifests/profile/base
mkdir -p $RPM_BUILD_ROOT/usr/share/openstack-puppet/modules/tripleo/manifests/profile/base
cp ciscoaci_ml2.pp $RPM_BUILD_ROOT/usr/share/openstack-puppet/modules/tripleo/manifests/profile/base
cp ciscoaci_aim.pp $RPM_BUILD_ROOT/usr/share/openstack-puppet/modules/tripleo/manifests/profile/base
cp ciscoaci_compute.pp $RPM_BUILD_ROOT/usr/share/openstack-puppet/modules/tripleo/manifests/profile/base
cp ciscoaci_opflex.pp $RPM_BUILD_ROOT/usr/share/openstack-puppet/modules/tripleo/manifests/profile/base

%post
if [ "$1" = "1" ]; then
   ln -s /usr/share/openstack-puppet/modules/ciscoaci /etc/puppet/modules/ciscoaci
fi

%postun
if [ "$1" = "0" ]; then
  # Perform tasks to prepare for the initial installation
  unlink /etc/puppet/modules/ciscoaci
elif [ "$1" = "2" ]; then
  # Perform whatever maintenance must occur before the upgrade begins
  echo ""
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/usr/share/openstack-puppet/modules/ciscoaci
/usr/share/openstack-puppet/modules/tripleo/manifests/profile/base/ciscoaci_ml2.pp
/usr/share/openstack-puppet/modules/tripleo/manifests/profile/base/ciscoaci_aim.pp
/usr/share/openstack-puppet/modules/tripleo/manifests/profile/base/ciscoaci_compute.pp
/usr/share/openstack-puppet/modules/tripleo/manifests/profile/base/ciscoaci_opflex.pp
