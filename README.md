# RHEL_STIG_WORK
RHEL_STIG_WORK


##########################################################################################
###    Ansible Playbook To Check and Remediate ACAS Open Finding V-204392              ###
#                                 ====== USAGE  ========                               ###
###                   Execute playbook from /opt/ansible directory                     ###
### ansible-playbook playbooks/stig_remediation/v204392/remediate_v204392_finding.yml  ###
###         -i env/stig_remediation/v204392/hosts.yml -e target=test1  -kK             ###
##########################################################################################
---
- name: Check and Remediate STIG Finding V-204392
  hosts: "{{ target }}"
  become: yes
  serial: 1
  tasks:
      - name: Create Empty Files To Store File Details
        file:
          path: "{{ item }}"
          state: touch
        loop:
          - /tmp/{{ ansible_fqdn }}_files_perm.txt
          - /tmp/{{ ansible_fqdn }}_files_perm_remdtn.txt
        delegate_to: localhost

      - name: Generate List of Files With Incorrect Permission
        shell: >
           for i in `rpm -Va | grep -E '^.{1}M|^.{5}U|^.{6}G' | cut -d " " -f 4,5`; do for j in `rpm -qf $i`;do rpm -ql $j --dump | cut -d " " -f 1,5,6,7 | grep $i;done;done | awk '{print $1}' | sort -u
        register: files

      - name: Display Files
        debug:
         var: files.stdout_lines

      - name: Check Permission on Files Before Remediation
        shell: ls -l {{ item }}
        loop: "{{ files.stdout_lines }}"
        register: perm_list

      - name: Display Perms
        debug:
          msg: "{{ perm_list.results | map(attribute='stdout') }}"

      - name: Save File Permissions To a File
        copy:
          content: "{{ perm_list.results | map(attribute='stdout' ) | join('\n')  }}"
          dest: /tmp/{{ ansible_fqdn }}_files_perm.txt
        delegate_to: localhost

      - name: Get Packages With Incorrect File Permissions or Ownership
        shell: |
            rpm -Va --nolinkto --nofiledigest --nosize --nomtime --nodigest --nosignature | grep -E '^(.M|.....U|......G)' | tee /dev/stderr | cut -c13- | sed 's/^ //' | xargs rpm -qf | sort -u
        register: pkg_list

      - name: Display output
        debug:
          msg: "{{ pkg_list.stdout_lines }}"

      - name: Reset File Permissions/Ownership To Vendor Values
        shell: |
          rpm --restore {{ item }}
        register: remdtn_output
        ignore_errors: true
        loop: "{{ pkg_list.stdout_lines }}"

      - debug:
          var: remdtn_output

      - name: Display Error Encountered During Remediation
        debug:
            #msg: "{{ remdtn_output.results | map(attribute='stderr_lines') }}"
            msg: "{{ item.stderr_lines }}"
        #changed_when: true
       loop: "{{ remdtn_output.results }}"
        #when:
          #  - remdtn_output is changed
         #   - item is failed

      - name: Get Permission On Each File After Remediation
        shell: ls -l {{ item }}
        loop: "{{ files.stdout_lines }}"
        register: fixed_perm_list

      - name: Display Perms
        debug:
          msg: "{{ fixed_perm_list.results | map(attribute='stdout') }}"

      - name: Save Fixed File Permissions
        copy:
          content: "{{ fixed_perm_list.results | map(attribute='stdout' ) | join('\n')  }}"
          dest: /tmp/{{ ansible_fqdn }}_files_perm_remdtn.txt
        delegate_to: localhost
