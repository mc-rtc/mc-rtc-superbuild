set(CONFIG_SKIPLIST_COMMAND "${CMAKE_COMMAND}" -E chdir "${WKS_DIR}")

if("${ROS_DISTRO}" STREQUAL "melodic")
  set(SKIPLIST_OPTION "--blacklist")
  set(NO_SKIPLIST_OPTION "--no-blacklist")
else()
  set(SKIPLIST_OPTION "--skiplist")
  set(NO_SKIPLIST_OPTION "--no-skiplist")
endif()

file(STRINGS "${SKIPLIST_FILE}" SKIPLIST)
list(LENGTH SKIPLIST N_SKIPLIST)
if(N_SKIPLIST EQUAL 0)
  set(CONFIG_SKIPLIST_COMMAND ${CONFIG_SKIPLIST_COMMAND} catkin config
                              ${NO_SKIPLIST_OPTION}
  )
  set(CONFIG_SKIPLIST_COMMAND_COMMENT "Clearing skiplist for ${WKS}")
else()
  set(CONFIG_SKIPLIST_COMMAND ${CONFIG_SKIPLIST_COMMAND} catkin config
                              ${SKIPLIST_OPTION} ${SKIPLIST}
  )
  list(JOIN SKIPLIST " " SKIPLIST_STR)
  set(CONFIG_SKIPLIST_COMMAND_COMMENT "Set skiplist for ${WKS}: ${SKIPLIST_STR}")
endif()

message(STATUS "${CONFIG_SKIPLIST_COMMAND_COMMENT}")
execute_process(COMMAND ${CONFIG_SKIPLIST_COMMAND} COMMAND_ERROR_IS_FATAL ANY)
file(TOUCH "${SKIPLIST_STAMP}")
