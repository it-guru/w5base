#!/bin/bash
mysqladmin drop w5base2
mysqladmin create w5base2
mysql w5base2 < master.sql
