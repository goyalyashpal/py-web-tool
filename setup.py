#!/usr/bin/env python3
"""Setup for pyWeb."""

from distutils.core import setup

setup(name='py-web-tool',
      version='3.2',
      description='py-web-tool 3.2: Yet Another Literate Programming Tool',
      author='S. Lott',
      author_email='slott56@gmail.com',
      url='http://slott-softwarearchitect.blogspot.com/',
      py_modules=['src/pyweb'],
      install_requires=['jinja2'],
      classifiers=[
          'Intended Audience :: Developers',
          'Topic :: Documentation',
          'Topic :: Software Development :: Documentation', 
          'Topic :: Text Processing :: Markup',
      ]
   )
