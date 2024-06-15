#!/bin/bash

# apologies for the language but its 4am on a saturday and i wanna fucking sleep
# will clean up later i just want this shit pushed to git

# There's gonna be some stupid ass error if we don't use redhat's daemon
dbus-daemon --system --fork

# Other daemons need to run too because shit wont work
virtlockd &                                            # detaching like this might be a cockblock, fix l8r
virtlogd &

# Btw this will vomit a shitload of udev errors but it shouldnt be a problem
# idk why it does this but it hasnt caused an issue where i need to fix anything...yet
libvirtd -l -f /etc/libvirt/libvirtd.conf