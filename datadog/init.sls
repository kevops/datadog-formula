{% if grains['os'].lower() in ('ubuntu', 'debian') %}
datadog-apt-https:
  pkg.installed:
    - name: apt-transport-https
{% endif %}

datadog:
  pkgrepo:
    - managed
    - humanname: Datadog, Inc.
    {% if grains['os'].lower() in ('ubuntu', 'debian') %}
    - name: deb http://apt.datadoghq.com/ stable main
    - keyserver: keyserver.ubuntu.com
    - keyid: C7A7DA52
    - file: /etc/apt/sources.list.d/datadog.list
    - require:
      - pkg: datadog-apt-https
    {% elif grains['os_family'] == 'RedHat' %}
    - file: /etc/yum.repos.d/datadog.repo
    - baseurl: http://yum.datadoghq.com/rpm/x86_64
    - enabled: 1
    - gpgcheck: 1
    - gpgkey: https://yum.datadoghq.com/DATADOG_RPM_KEY.public
    {% endif %}

datadog-pkg:
  pkg.latest:
    - name: datadog-agent
    - require:
      - pkgrepo: datadog
 
datadog-example:
  cmd.run:
    - name: cp /etc/dd-agent/datadog.conf.example /etc/dd-agent/datadog.conf
    # copy just if datadog.conf does not exists yet and the .example exists
    - onlyif: test ! -f /etc/dd-agent/datadog.conf -a -f /etc/dd-agent/datadog.conf.example
    - require:
      - pkg: datadog-pkg
 
datadog-conf:
  file.replace:
    - name: /etc/dd-agent/datadog.conf
    - pattern: "api_key:(.*)"
    - repl: "api_key: {{ pillar['datadog']['api_key'] }}"
    - count: 1
    - watch:
      - pkg: datadog-pkg
    - require:
      - cmd: datadog-example
 
datadog-agent-service:
  service:
    - name: datadog-agent
    - running
    - enable: True
    - watch:
      - pkg: datadog-agent
