macro(GAP_configure_linker project_name)
  set(GAP_USER_LINKER_OPTION
    "DEFAULT"
      CACHE STRING "Linker to be used")
    set(GAP_USER_LINKER_OPTION_VALUES "DEFAULT" "SYSTEM" "LLD" "GOLD" "BFD" "MOLD" "SOLD" "APPLE_CLASSIC" "MSVC")
  set_property(CACHE GAP_USER_LINKER_OPTION PROPERTY STRINGS ${GAP_USER_LINKER_OPTION_VALUES})
  list(
    FIND
    GAP_USER_LINKER_OPTION_VALUES
    ${GAP_USER_LINKER_OPTION}
    GAP_USER_LINKER_OPTION_INDEX)

  if(${GAP_USER_LINKER_OPTION_INDEX} EQUAL -1)
    message(
      STATUS
        "Using custom linker: '${GAP_USER_LINKER_OPTION}', explicitly supported entries are ${GAP_USER_LINKER_OPTION_VALUES}")
  endif()

  set_target_properties(${project_name} PROPERTIES LINKER_TYPE "${GAP_USER_LINKER_OPTION}")
endmacro()
