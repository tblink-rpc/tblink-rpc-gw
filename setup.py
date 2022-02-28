
import os, stat
from setuptools import setup
from setuptools.command.install import install

rootdir = os.path.dirname(os.path.realpath(__file__))

version="0.0.1"

if "BUILD_NUM" in os.environ.keys():
    version += "." + os.environ["BUILD_NUM"]

setup(
  name = "tblink-rpc-gw",
  version = version,
  packages=['tblink_rpc_gw'],
  package_dir = {'' : 'python'},
  author = "Matthew Ballance",
  author_email = "matt.ballance@gmail.com",
  description = ("TbLink-RPC Gateware integration."),
  license = "Apache 2.0",
  keywords = ["SystemVerilog", "Verilog", "RTL"],
  url = "https://github.com/tblink-rpc/tblink-rpc-gw",
  entry_points={
  },
  setup_requires=[
    'setuptools_scm',
  ],
  install_requires=[
      'pyyaml',
      'pykwalify',
      'pyyaml-srcinfo-loader',
  ],
)

