#include "MyFirstController.h"

MyFirstController::MyFirstController(mc_rbdyn::RobotModulePtr rm, double dt, const mc_rtc::Configuration & config)
: mc_control::MCController(rm, dt)
{
  config_.load(config);
  solver().addConstraintSet(contactConstraint);
  solver().addConstraintSet(kinematicsConstraint);
  solver().addTask(postureTask);
  solver().setContacts();

  jointIndex = robot().jointIndexByName("NECK_Y");

  mc_rtc::log::success("MyFirstController init done");
}

bool MyFirstController::run()
{
  if(std::abs(postureTask->posture()[jointIndex][0] - robot().mbc().q[jointIndex][0]) < 0.05)
  {
    switch_target();
  }
  return mc_control::MCController::run();
}

void MyFirstController::reset(const mc_control::ControllerResetData & reset_data)
{
  mc_control::MCController::reset(reset_data);
}

void MyFirstController::switch_target()
{
  std::map<std::string, std::vector<double>> targetPosture;

  if(goingLeft)
  {
      targetPosture["NECK_Y"] = {0.5};  // radians, looking left
  }
  else
  {
      targetPosture["NECK_Y"] = {-0.5};
  }
  postureTask->target(targetPosture);

  goingLeft = !goingLeft;
}

CONTROLLER_CONSTRUCTOR("MyFirstController", MyFirstController)