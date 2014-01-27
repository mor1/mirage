(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** Configuration library.

    [Mirage_types] defines a set of well-defined module signatures
    which are used by the various mirage libraries to implement a
    large collection of devices. *)

(** {1 Module combinators} *)

type 'a typ
(** The type of values representing module types. *)

val (@->): 'a typ -> 'b typ -> ('a -> 'b) typ
(** Construct a functor type from a type and an existing functor
    type. This corresponds to prepending a parameter to the list of
    functor parameters. For example,

    {| kv_ro @-> ip @-> kv_ro |}

    describes a functor type that accepts two arguments -- a kv_ro and
    an ip device -- and returns a kv_ro.
*)

type 'a impl
(** The type of values representing module implementations. *)

val ($): ('a -> 'b) impl -> 'a impl -> 'b impl
(** [m $ a] applies the functor [a] to the functor [m]. *)

val foreign: string -> ?libraries:string list -> ?packages:string list -> 'a typ -> 'a impl
(** [foreign name libs packs constr typ] states that the module named
    by [name] has the module type [typ]. If [libs] is set, add the
    given set of ocamlfind libraries to the ones loaded by default. If
    [packages] is set, add the given set of OPAM packages to the ones
    loaded by default. *)

val typ: 'a impl -> 'a typ
(** Return the module signature of a given implementation. *)

(** {2 Consoles} *)

type console
(** Abstract type for consoles. *)

val console: console typ
(** Representation of [Mirage_types.CONSOLE]. *)

val default_console: console impl
(** Default console implementation. *)

val custom_console: string -> console impl
(** Custom console implementation. *)

(** {2 Filesystem configurations} *)

type kv_ro
(** Abstract type for read-only key/value store. *)

val kv_ro: kv_ro typ
(** Representation of [Mirage_types.KV_RO]. *)

val crunch: string -> kv_ro impl
(** Crunch a directory. *)

val direct_kv_ro: string -> kv_ro impl
(** Direct access to the underlying filesystem as a key/value
    store. For Xen backends, this is equivalent to [crunch]. *)

type block
(** Abstract type for raw block device configurations. *)

val block: block typ
(** Representation of [Mirage_types.BLOCK]. *)

val block_of_file: unit -> string -> block impl
(** Use the given filen as a raw block device. *)

type fs
(** Abstract type for filesystems. *)

val fs: fs typ
(** Representation of [Mirage_types.FS]. *)

val fat: block impl -> fs impl
(** Consider a raw block device as a FAT filesystem. *)

val fat_of_files: ?dir:string -> ?regexp:string -> unit -> fs impl
(** [fat_files dir ?dir ?regexp ()] collects all the files matching
    the shell pattern [regexp] in the directory [dir] into a FAT
    image. By default, [dir] is the current working directory and
    [regexp] is {i *} *)

val kv_ro_of_fs: unit -> fs impl -> kv_ro impl
(** Consider a filesystem implementation as a read-only key/value
    store. *)

(** {2 Network interfaces} *)

type network
(** Abstract type for network configurations. *)

val network: network typ
(** Representation of [Mirage_types.NETWORK]. *)

val tap0: network impl
(** The '/dev/tap0' interface. *)

val custom_network: string -> network impl
(** A custom network interface. *)

(** {2 IP configuration} *)

type ip
(** Abstract type for IP configurations. *)

val ip: ip typ
(** Representation of [Mirage_net.IP] *)

type ipv4 = {
  address: Ipaddr.V4.t;
  netmask: Ipaddr.V4.t;
  gateway: Ipaddr.V4.t list;
}
(** Types for IPv4 manual configuration. *)

val ipv4: ipv4 -> network impl list -> ip impl
(** Use an IPv4 address. *)

val default_ip: network impl list -> ip impl
(** Default local IP listening on the given network interfaces:
    - address: 10.0.0.2
    - netmask: 255.255.255.0
    - gateway: 10.0.0.1 *)

val dhcp: network impl list -> ip impl
(** Use DHCP. *)

(** {2 HTTP configuration} *)

type http
(** Abstract type for http configurations. *)

val http: http typ
(** Representation of [Cohttp.S]. *)

val http_server: int -> ip impl -> http impl
(** Serve on the given port, with the given IP configuration. *)

(** {2 Jobs} *)

type job
(** Type for job values. *)

val job: job typ
(** Reprensention of [JOB]. *)

val register: string -> job impl list -> unit
(** [register name jobs] registers the application named by [name]
    which will executes the given [jobs]. *)

type t = {
  name: string;
  root: string;
  jobs: job impl list;
}
(** Type for values representing a project description. *)

val load: string option -> t
(** Read a config file. If no name is given, search for use
    [config.ml]. *)

(** {2 Device configuration} *)

type mode = [
  | `Unix of [ `Direct | `Socket ]
  | `Xen
]
(** Configuration mode. *)

val set_mode: mode -> unit
(** Set the configuration mode for the current project. *)

val get_mode: unit -> mode

module Impl: sig

  (** Configurable device. *)

  val name: 'a impl -> string
  (** The unique variable name of the value of type [t]. *)

  val module_name: 'a impl -> string
  (** The unique module name for the given implementation. *)

  val packages: 'a impl -> string list
  (** List of OPAM packages to install for this device. *)

  val libraries: 'a impl -> string list
  (** List of ocamlfind libraries. *)

  val configure: 'a impl -> unit
  (** Generate some code to create a value with the right
      configuration settings. *)

  val clean: 'a impl -> unit
  (** Remove all the autogen files. *)

end

(** {2 Project configuration} *)

val manage_opam_packages: bool -> unit
(** Tell Irminsule to manage the OPAM configuration
    (ie. install/remove missing packages). *)

val add_to_opam_packages: string list -> unit
(** Add some base OPAM package to install *)

val add_to_ocamlfind_libraries: string list -> unit
(** Link with the provided additional libraries. *)

val packages: t -> string list
(** List of OPAM packages to install for this project. *)

val libraries: t -> string list
(** List of ocamlfind libraries. *)

val configure: t -> unit
(** Generate some code to create a value with the right
    configuration settings. *)

val clean: t -> unit
(** Remove all the autogen files. *)

val build: t -> unit
(** Call [make build] in the right directory. *)

val run: t -> unit
(** call [make run] in the right directory. *)

(** {2 Extensions} *)

module type CONFIGURABLE = sig

  (** Signature for configurable devices. *)

  type t
  (** Abstract type for configurable devices. *)

  val name: t -> string
  (** Return the unique variable name holding the state of the given
      device. *)

  val module_name: t -> string
  (** Return the name of the module implementing the given device. *)

  val packages: t -> string list
  (** Return the list of OPAM packages which needs to be installed to
      use the given device. *)

  val libraries: t -> string list
  (** Return the list of ocamlfind libraries to link with the
      application to use the given device. *)

  val configure: t -> unit
  (** Configure the given device. *)

  val clean: t -> unit
  (** Clean all the files generated to use the given device. *)

  val update_path: t -> string -> t
  (** [update_path t root] prefixes all the path appearing in [t] with
      the the prefix [root]. *)

end

val implementation: 'a -> 'b -> (module CONFIGURABLE with type t = 'b) -> 'a impl
(** Extend the library with an external configuration. *)

val append_main: ('a, unit, string, unit) format4 -> 'a
(** Add some string to [main.ml]. *)

val newline_main: unit -> unit
(** Add a newline to [main.ml]. *)

module Io_page: CONFIGURABLE with type t = unit
(** Implementation of IO page allocators. *)

module Clock: CONFIGURABLE with type t = unit
(** Implementation of clocks. *)

module Console: CONFIGURABLE with type t = string
(** Implementation of consoles. *)

module Crunch: CONFIGURABLE with type t = string
(** Implementation of crunch a local filesystem. *)

module Direct_kv_ro: CONFIGURABLE with type t = string
(** Implementation of direct access to the filesystem as a key/value
    read-only store. *)

module Block: CONFIGURABLE with type t = string
(** Implementation of raw block device. *)

module Fat: CONFIGURABLE with type t = block impl
(** Implementatin of the Fat filesystem. *)

type network_config = Tap0 | Custom of string
(** Network configuration. *)

module Network: CONFIGURABLE with type t = network_config
(** Implementation of network configuration. *)

module IP: CONFIGURABLE

module HTTP: CONFIGURABLE

module Job: CONFIGURABLE

(** {2 Generation of fresh names} *)

module Name: sig

  val create: string -> string
  (** [create base] creates a fresh name using the given [base]. *)

  val of_key: string -> base:string -> string
  (** [find_or_create key base] returns a unique name corresponding to
      the key. *)

end
