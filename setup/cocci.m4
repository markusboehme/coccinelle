dnl
dnl  autoconf helper macros for coccinelle
dnl

dnl  check if the ocaml version is recent enough
dnl    $1: version to test against
AC_DEFUN([AC_CHECK_OCAMLVERSION],
[dnl
  AC_REQUIRE([AC_PROG_OCAML])
  AS_UNSET([versioncheck])
  AC_MSG_CHECKING([that the OCaml version is at least $1])
  AS_VERSION_COMPARE([$OCAMLVERSION],[$1],[versioncheck=no],[versioncheck=yes],[versioncheck=yes])
  AC_MSG_RESULT([$versioncheck])
  AS_IF([test "x$versioncheck" == xno],[AC_MSG_NOTICE([a more recent OCaml installation may be required])])
  AC_SUBST([OCAMLVERSIONOK], [$versioncheck])
])


dnl  using ocamlfind to store into $1 the location where
dnl  a package $2 resides.
AC_DEFUN([AC_COCCI_OCAMLPKGDIR],
[dnl
  $1=`$OCAMLFIND query $2 2>/dev/null`
])


dnl  stores the result of checking for the
dnl  ocaml package given as $2 in the
dnl  variable given as $1
AC_DEFUN([AC_COCCI_OCAMLPKG],
[dnl
  AS_UNSET([$1])
  AC_CHECK_OCAML_PKG([$2])
  $1="$found"   dnl  '$found' is set by AC_CHECK_OCAML_PKG
])

dnl  requires that the ocaml package is installed.
dnl  it is assumed that this package is part of the
dnl  ocaml installation.
AC_DEFUN([AC_REQ_COCCI_STDPKG],
[dnl
  AC_COCCI_OCAMLPKG([haveocamlpkg],[$1])
  AS_IF([test "x$haveocamlpkg" == xno],
  [dnl
    AC_MSG_ERROR([package $1 is required. It should be part of your ocaml installation.])
  ])
])


dnl  defines the COCCI_OCAML_EXTERNAL variable to point to the directory
dnl  with extra ocaml packages
AC_DEFUN([AC_COCCI_SET_EXTERNAL_DIR],
[dnl
  AC_ARG_VAR(COCCI_OCAML_EXTERNAL, [path to extra ocaml packages (default: $1)])
  AC_SUBST([COCCI_OCAML_EXTERNAL],[$1])
  AC_MSG_NOTICE([coccinelle may use external ocaml libraries in $COCCI_OCAML_EXTERNAL])
])


dnl  handle optional packages for which coccinelle may have
dnl  local versions.
dnl
dnl  Note: this macro sets additional variables for use with
dnl  'Makefile.config'.
dnl
dnl  variables:
dnl    enable_$1: either 'yes', 'local', or 'no'
AC_DEFUN([AC_CHECK_COCCI_EXTPKG],
[dnl
  AC_MSG_NOTICE([configuring package $1])
  AC_ARG_ENABLE([$1], AS_HELP_STRING([--enable-$1], [enable global package $1 (yes,no) (default: auto)]))

  dnl  try and find a globally installed version
  dnl  if not, enable_$1 will be "no"
  AS_IF([test "$enable_$1" != xno],
  [dnl
    AC_COCCI_OCAMLPKG([GLOBAL_$1], [$1])

    AS_IF([test "x$GLOBAL_$1" == xyes],
    [dnl  when the package is available
      AC_SUBST([enable_$1],[yes])
      AC_COCCI_OCAMLPKGDIR([PATH_$1], [$1])
    ],
    [dnl  when the package is not available
      AS_IF([test "x$enable_$1" == xyes],
      [dnl  when explicitly requested the global version
        AC_MSG_ERROR([OCaml package $1 is not available but requested explicitly])
      ])
      AC_SUBST([enable_$1],[no])
    ])
  ])

  dnl  check for a local package
  AS_IF([test "$enable_$1" == xno],
  [dnl
    AS_UNSET([pkgdir])
    pkgdir=$COCCI_OCAML_EXTERNAL/$1/
    AC_MSG_CHECKING([for a local substitute of $1])
    AS_IF([test -d "$pkgdir"],
    [dnl
      AC_MSG_RESULT([yes])
      AC_MSG_NOTICE([using local substitute for $1 in $pkgdir])
      AC_SUBST([enable_$1], [local])
      AC_SUBST([PATH_$1], [$pkgdir])
    ],
    [AC_MSG_RESULT([no, not found: $pkgdir])])
  ])

  dnl  additional handling
  AS_IF([test "$enable_$1" != xno],
  [dnl
    AC_SUBST([FEATURE_$1],[1])
    AC_SUBST([FLAGS_$1],['$(FLAGS_$1)'])

    dnl  distinguish global/local
    AS_IF([test "$enable_$1" == xlocal],
    [dnl
      AC_SUBST([MODULES_$1],['$(GLOBAL_$1)'])
      AC_SUBST([MODULESOPT_$1],['$(GLOBALOPT_$1)'])

      dnl check if the local directory has a Makefile
      AS_IF([test -f "$PATH_$1/Makefile"],
      [dnl
        AC_SUBST([MAKE_$1],[$PATH_$1])
      ],
      [dnl
        AC_SUBST([MAKE_$1],[ ])
      ])
    ],
    [dnl
      AC_SUBST([MODULES_$1],['$(LOCAL_$1)'])
      AC_SUBST([MODULESOPT_$1],['$(LOCALOPT_$1)'])
    ])
  ])
])


dnl  initializes the defaults substitutions for
dnl  configuration variables of packages
AC_DEFUN([AC_COCCI_INIT_PKG_DEFAULT],
[dnl
  AC_SUBST([FEATURE_$1])
  AC_SUBST([FLAGS_$1])
  AC_SUBST([MODULES_$1])
  AC_SUBST([MODULESOPT_$1])
])


dnl  version of AC_CHECK_COCCI_EXTPKG that fails with an
dnl  error if the package could not be found and no local
dnl  substitute is available.
AC_DEFUN([AC_REQ_COCCI_EXTPKG],
[dnl
  AC_CHECK_COCCI_EXTPKG([$1])
  AS_IF([test "x$enable_s1" == xno],
  [dnl
    AC_MSG_ERROR([OCaml package $1 is required. Please make sure it is available.])
  ])
])
