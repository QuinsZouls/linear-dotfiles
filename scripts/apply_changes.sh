#!/bin/bash
yes | cp -TRv ../config/awesome/ ~/.config/awesome/
echo "Changes applied, please restarting awesome..."
awesome-client "awesome.restart()"