#!/usr/bin/env bash

cd `dirname $0`/../..

pub run test -p vm -p content-shell -p firefox

cd -