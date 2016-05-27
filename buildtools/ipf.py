#! /usr/bin/env python

import struct
import sys
import os
import zlib
import argparse

from binascii import crc32

SUPPORTED_FORMATS = (bytearray(b'\x50\x4b\x05\x06'),)
UNCOMPRESSED_EXT = (".jpg", ".JPG", ".fsb", ".mp3")

class IpfInfo(object):
    """
    This class encapsulates information about a file entry in an IPF archive.

    Attributes:
        filename: A string representing the path and name of the file.
        archivename: The name of the originating IPF archive.
        filename_length: Length of the filename.
        archivename_length: Length of the archive name.
        compressed_length: The length of the compressed file data.
        uncompressed_length: The length of the uncompressed file data.
        data_offset: Offset in the archive file where data for this file begins.
    """

    def __init__(self, filename=None, archivename=None, datafile=None):
        """
        Inits IpfInfo class.
        """
        self._filename_length = 0
        self._unknown1 = None
        self._compressed_length = 0
        self._uncompressed_length = 0
        self._data_offset = 0
        self._archivename_length = 0

        self._filename = filename
        self._archivename = archivename
        self.datafile = datafile

        if filename:
            self._filename_length = len(filename)
        if archivename:
            self._archivename_length = len(archivename)

    @classmethod
    def from_buffer(self, buf):
        """
        Creates IpfInfo instance from a data buffer.
        """
        info = IpfInfo()
        data = struct.unpack('<HIIIIH', buf)

        info._filename_length = data[0]
        info._crc = data[1]
        info._compressed_length = data[2]
        info._uncompressed_length = data[3]
        info._data_offset = data[4]
        info._archivename_length = data[5]
        return info

    def to_buffer(self):
        """
        Creates a data buffer that represents this instance.
        """
        data = struct.pack('<HIIIIH', self.filename_length, self.crc, self.compressed_length, self.uncompressed_length, self.data_offset, self.archivename_length)
        data += self.archivename.encode("ascii")
        data += self.filename.encode("ascii")
        return data

    @property
    def filename(self):
        return self._filename

    @property
    def archivename(self):
        return self._archivename

    @property
    def filename_length(self):
        return self._filename_length

    @property
    def archivename_length(self):
        return self._archivename_length

    @property
    def compressed_length(self):
        return self._compressed_length

    @property
    def uncompressed_length(self):
        return self._uncompressed_length

    @property
    def data_offset(self):
        return self._data_offset

    @property
    def crc(self):
        return self._crc

    @property
    def key(self):
        return '%s_%s' % (self.archivename.lower(), self.filename.lower())

class IpfArchive(object):
    """
    Class that represents an IPF archive file.
    """

    def __init__(self, name, verbose=False, revision=0, base_revision=0):
        """
        Inits IpfArchive with a file `name`.

        Note: IpfArchive will immediately try to open the file. If it does not exist, an exception will be raised.
        """
        self.name = name
        self.verbose = verbose
        self.revision = revision
        self.base_revision = base_revision
        self.fullname = os.path.abspath(name)
        _, self.archivename = os.path.split(self.name)
        
        self.file_handle = None
        self.closed = True

        self._files = None

    @property
    def files(self):
        if self._files is None:
            raise Exception('File has not been opened yet!')
        return self._files    

    def close(self):
        """
        Closes all file handles if they are not already closed.
        """
        if self.closed:
            return

        if self.file_handle.mode.startswith('w'):
            self._write()

        if self.file_handle:
            self.file_handle.close()
        self.closed = True

    def open(self, mode='rb'):
        if not self.closed:
            return

        self.file_handle = open(self.name, mode)
        self.closed = False
        self._files = {}

        if mode.startswith('r'):
            self._read()

    def _read(self):
        self.file_handle.seek(-24, 2)
        self._archive_header = self.file_handle.read(24)
        self._file_size = self.file_handle.tell()

        self._archive_header_data = struct.unpack('<HIHI4sII', self._archive_header)
        self.file_count = self._archive_header_data[0]
        self._filetable_offset = self._archive_header_data[1]

        self._filefooter_offset = self._archive_header_data[3]
        self._format = self._archive_header_data[4]
        self.base_revision = self._archive_header_data[5]
        self.revision = self._archive_header_data[6]

        if self._format not in SUPPORTED_FORMATS:
            raise Exception('Unknown archive format: %s' % repr(self._format))

        # start reading file list
        self.file_handle.seek(self._filetable_offset, 0)
        for i in range(self.file_count):
            buf = self.file_handle.read(20)
            info = IpfInfo.from_buffer(buf)
            info._archivename = self.file_handle.read(info.archivename_length)
            info._filename = self.file_handle.read(info.filename_length)

            if info.key in self.files:
                # duplicate file name?!
                raise Exception('Duplicate file name: %s' % info.filename)

            self.files[info.key] = info

    def _write(self):
        pos = 0
        # write data entries first
        for key in self.files:
            fi = self.files[key]

            # read data
            f = open(fi.datafile, 'rb')
            data = f.read()
            f.close()

            fi._crc = crc32(data) & 0xffffffff
            fi._uncompressed_length = len(data)

            # check for extension
            _, extension = os.path.splitext(fi.filename)
            if extension in UNCOMPRESSED_EXT:
                # write data uncompressed
                self.file_handle.write(data)
                fi._compressed_length = fi.uncompressed_length
            else:
                # compress data
                deflater = zlib.compressobj(6, zlib.DEFLATED, -15)
                compressed = deflater.compress(data)
                compressed += deflater.flush()
                self.file_handle.write(compressed)
                fi._compressed_length = len(compressed)
                deflater = None

            # update file info
            fi._data_offset = pos
            pos += fi.compressed_length

        self._filetable_offset = pos

        # write the file table
        for key in self.files:
            fi = self.files[key]
            buf = fi.to_buffer()
            self.file_handle.write(buf)
            pos += len(buf)

        # write archive footer
        buf = struct.pack('<HIHI4sII', len(self.files), self._filetable_offset, 0, pos, SUPPORTED_FORMATS[0], self.base_revision, self.revision)
        self.file_handle.write(buf)

    def get(self, filename, archive=None):
        """
        Retrieves the `IpfInfo` object for `filename`.

        Args:
            filename: The name of the file.
            archive: The name of the archive. Defaults to the current archive

        Returns:
            An `IpfInfo` instance that describes the file entry.
            If the file could not be found, None is returned.
        """
        if archive is None:
            archive = self.archivename
        key = '%s_%s' % (archive.lower(), filename.lower())
        if key not in self.files:
            return None
        return self.files[key]

    def get_data(self, filename, archive=None):
        """
        Returns the uncompressed data of `filename` in the archive.

        Args:
            filename: The name of the file.
            archive: The name of the archive. Defaults to the current archive

        Returns:
            A string of uncompressed data.
            If the file could not be found, None is returned.
        """
        info = self.get(filename, archive)
        if info is None:
            return None
        self.file_handle.seek(info.data_offset)
        data = self.file_handle.read(info.compressed_length)
        if info.compressed_length == info.uncompressed_length:
            return data
        return zlib.decompress(data, -15)

    def extract_all(self, output_dir, overwrite=False):
        """
        Extracts all files into a directory.

        Args:
            output_dir: A string describing the output directory.
        """
        for filename in self.files:
            info = self.files[filename]
            output_file = os.path.join(output_dir, info.archivename, info.filename)

            if self.verbose:
                print('%s: %s' % (info.archivename, info.filename))

            # print output_file
            # print info.__dict__
            if not overwrite and os.path.isfile(output_file):
                continue
            head, tail = os.path.split(output_file)
            try:
                os.makedirs(head)
            except os.error:
                pass

            f = open(output_file, 'wb')
            try:
                data = self.get_data(info.filename, info.archivename)
                f.write(data)
            except Exception as e:
                print('Could not unpack %s' % info.filename)
                print(info.__dict__)
                print(e)
                print(data)
            f.close()

    def add(self, name, archive=None, newname=None):
        if archive is None:
            archive = self.archivename

        mode = 'Adding'
        fi = IpfInfo(newname or name, archive, datafile=name)
        if fi.key in self.files:
            mode = 'Replacing'
        if self.verbose:
            print('%s %s: %s' % (mode, fi.archivename, fi.filename))
        self.files[fi.key] = fi


def print_meta(ipf, args):
    print('{:<15}: {:}'.format('File count', ipf.file_count))
    print('{:<15}: {:}'.format('First file', ipf._filetable_offset))
    print('{:<15}: {:}'.format('Unknown', ipf._archive_header_data[2]))
    print('{:<15}: {:}'.format('Archive header', ipf._filefooter_offset))
    print('{:<15}: {:}'.format('Format', repr(ipf._format)))
    print('{:<15}: {:}'.format('Base revision', ipf.base_revision))
    print('{:<15}: {:}'.format('Revision', ipf.revision))

def print_list(ipf, args):
    for k in ipf.files:
        f = ipf.files[k]
        print('%s _ %s' % (f.archivename, f.filename))

        # crc check
        # data = ipf.get_data(k)
        # print('%s / %s / %s' % (f.crc, crc32(data) & 0xffffffff, ''))

def get_norm_relpath(path, start):
    newpath = os.path.normpath(os.path.relpath(path, args.target))
    if newpath == '.':
        return ''
    return newpath

def create_archive(ipf, args):
    if not args.target:
        raise Exception('No target for --create specified')

    _, filename = os.path.split(ipf.name)

    if os.path.isdir(args.target):
        for root, dirs, files in os.walk(args.target):
            # strip target path
            path = get_norm_relpath(root, args.target)

            # get archivename
            archive = filename
            components = path.split(os.path.sep)
            if components[0].endswith('.ipf'):
                archive = components[0]

            if path.startswith(archive):
                path = path[len(archive) + 1:]
            
            for f in files:
                newname = '/'.join(path.replace('\\', '/').split('/')) + '/' + f
                ipf.add(os.path.join(root, f), archive=archive, newname=newname.strip('/'))

    elif os.path.isfile(args.target):
        # TODO: Calculate relative path and stuff
        ipf.add(args.target)
    else:
        raise Exception('Target for --create not found')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # functions
    parser.add_argument('-t', '--list', action='store_true', help='list the contents of an archive')
    parser.add_argument('-x', '--extract', action='store_true', help='extract files from an archive')
    parser.add_argument('-m', '--meta', action='store_true', help='show meta information of an archive')
    parser.add_argument('-c', '--create', action='store_true', help='create archive from target')
    # options
    parser.add_argument('-f', '--file', help='use archive file')
    parser.add_argument('-v', '--verbose', action='store_true', help='verbosely list files processed')
    parser.add_argument('-C', '--directory', metavar='DIR', help='change directory to DIR')
    parser.add_argument('-r', '--revision', type=int, help='revision number for the archive')
    parser.add_argument('-b', '--base-revision', type=int, help='base revision number for the archive')

    parser.add_argument('target', nargs='?', help='target file/directory to be extracted or packed')

    args = parser.parse_args()

    if args.list and args.extract:
        parser.print_help()
        print('You can only use one function!')
    elif not any([args.list, args.extract, args.meta, args.create]):
        parser.print_help()
        print('Please specify a function!')
    else:
        if not args.file:
            parser.print_help()
            print('Please specify a file!')
        else:
            ipf = IpfArchive(args.file, verbose=args.verbose)

            if not args.create:
                ipf.open()
            else:
                ipf.open('wb')

            if args.revision:
                ipf.revision = args.revision
            if args.base_revision:
                ipf.base_revision = args.base_revision

            if args.meta:
                print_meta(ipf, args)

            if args.list:
                print_list(ipf, args)
            elif args.extract:
                ipf.extract_all(args.directory or '.')
            elif args.create:
                create_archive(ipf, args)

            ipf.close()
