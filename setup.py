from setuptools import setup


def main():
    setup(name='simple_transmission_exporter',
          packages=['simple_transmission_exporter'],
          entry_points={
              'console_scripts': [
                  'simple-transmission-exporter = simple_transmission_exporter.simple_transmission_exporter:main'
              ]})


if __name__ == '__main__':
    main()
