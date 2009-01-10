/* posix.vapi
 *
 * Copyright (C) 2008  Emmanuele Bassi
 * Copyright (C) 2008  Matias De la Puente
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Authors:
 *  Matias De la Puente <mfpuente.ar@gmail.com>
 *  Emmanuele Bassi
 */

namespace POSIX
{
	[CCode (lower_case_cprefix = "", cheader_filename = "errno.h")]
	namespace Error
	{
		// see errno(3)
		public const int E2BIG;
		public const int EACCES;
		public const int EADDRINUSE;
		public const int EADDRNOTAVAIL;
		public const int EAFNOSUPPORT;
		public const int EAGAIN;
		public const int EALREADY;
		public const int EBADE;
		public const int EBADF;
		public const int EBADFD;
		public const int EBADMSG;
		public const int EBADR;
		public const int EBADRQC;
		public const int EBADSLT;
		public const int EBUSY;
		public const int ECANCELED;
		public const int ECHILD;
		public const int ECHRNG;
		public const int ECOMM;
		public const int ECONNABORTED;
		public const int ECONNREFUSED;
		public const int ECONNRESET;
		public const int EDEADLK;
		public const int EDEADLOCK;
		public const int EDESTADDRREQ;
		public const int EDOM;
		public const int EDQUOT;
		public const int EEXIST;
		public const int EFAULT;
		public const int EFBIG;
		public const int EHOSTDOWN;
		public const int EHOSTUNREACH;
		public const int EIDRM;
		public const int EILSEQ;
		public const int EINPROGRESS;
		public const int EINTR;
		public const int EINVAL;
		public const int EIO;
		public const int EISCONN;
		public const int EISDIR;
		public const int EISNAM;
		public const int EKEYEXPIRED;
		public const int EKEYREJECTED;
		public const int EKEYREVOKED;
		public const int EL2HLT;
		public const int EL2NSYNC;
		public const int EL3HLT;
		public const int EL3RST;
		public const int ELIBACC;
		public const int ELIBBAD;
		public const int ELIBMAX;
		public const int ELIBSCN;
		public const int ELIBEXEC;
		public const int ELOOP;
		public const int EMEDIUMTYPE;
		public const int EMFILE;
		public const int EMLINK;
		public const int EMSGSIZE;
		public const int EMULTIHOP;
		public const int ENAMETOOLONG;
		public const int ENETDOWN;
		public const int ENETRESET;
		public const int ENETUNREACH;
		public const int ENFILE;
		public const int ENOBUFS;
		public const int ENODATA;
		public const int ENODEV;
		public const int ENOENT;
		public const int ENOEXEC;
		public const int ENOKEY;
		public const int ENOLCK;
		public const int ENOLINK;
		public const int ENOMEDIUM;
		public const int ENOMEM;
		public const int ENOMSG;
		public const int ENONET;
		public const int ENOPKG;
		public const int ENOPROTOOPT;
		public const int ENOSPC;
		public const int ENOSR;
		public const int ENOSTR;
		public const int ENOSYS;
		public const int ENOTBLK;
		public const int ENOTCONN;
		public const int ENOTDIR;
		public const int ENOTEMPTY;
		public const int ENOTSOCK;
		public const int ENOTSUP;
		public const int ENOTTY;
		public const int ENOTUNIQ;
		public const int ENXIO;
		public const int EOPNOTSUPP;
		public const int EOVERFLOW;
		public const int EPERM;
		public const int EPFNOSUPPORT;
		public const int EPIPE;
		public const int EPROTO;
		public const int EPROTONOSUPPORT;
		public const int EPROTOTYPE;
		public const int ERANGE;
		public const int EREMCHG;
		public const int EREMOTE;
		public const int EREMOTEIO;
		public const int ERESTART;
		public const int EROFS;
		public const int ESHUTDOWN;
		public const int ESPIPE;
		public const int ESOCKTNOSUPPORT;
		public const int ESRCH;
		public const int ESTALE;
		public const int ESTRPIPE;
		public const int ETIME;
		public const int ETIMEDOUT;
		public const int ETXTBSY;
		public const int EUCLEAN;
		public const int EUNATCH;
		public const int EUSERS;
		public const int EWOULDBLOCK;
		public const int EXDEV;
		public const int EXFULL;

		// this is a const int because you're only supposed to copy
		// the errno value, not change it
		public const int errno;

		[CCode (cname = "strerror")]
		public static weak string to_string (int err_no);

		[CCode (cname = "perror")]
		public static void print_error (string? prefix = null);
	}
}
