#!/usr/bin/env python3

#############################################################################
##
## Copyright (C) 2020 The Qt Company Ltd.
## Contact: http://www.qt.io/licensing/
##
## This file is the CI build utilities of the Qt Toolkit.
##
## $QT_BEGIN_LICENSE:GPL-EXCEPT$
## Commercial License Usage
## Licensees holding valid commercial Qt licenses may use this file in
## accordance with the commercial license agreement provided with the
## Software or, alternatively, in accordance with the terms contained in
## a written agreement between you and The Qt Company. For licensing terms
## and conditions see https://www.qt.io/terms-conditions. For further
## information use the contact form at https://www.qt.io/contact-us.
##
## GNU General Public License Usage
## Alternatively, this file may be used under the terms of the GNU
## General Public License version 3 as published by the Free Software
## Foundation with exceptions as appearing in the file LICENSE.GPL3-EXCEPT
## included in the packaging of this file. Please review the following
## information to ensure the GNU General Public License requirements will
## be met: https://www.gnu.org/licenses/gpl-3.0.html.
##
## $QT_END_LICENSE$
##
#############################################################################


# For each dependency listed in depndencies.yaml, print a line like:
#   $dep_name $ref
#
# Options
#   -i/--input    YAML input file, defaults to depedencies.yaml
#   (TODO) --required    lists only required dependencies


import yaml
import argparse


parser = argparse.ArgumentParser(
    description='Read and list Qt modules dependencies from dependencies.yaml file')
parser.add_argument('-i', '--input', default='dependencies.yaml',
                    help='YAML input file')
args = parser.parse_args()

with open(args.input) as f:
    yaml_dict = yaml.safe_load(f)

deps = yaml_dict.get('dependencies')
for (name, value) in deps.items():
    print(name.lstrip('./'), value["ref"])
