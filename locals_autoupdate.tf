locals {
  kured_options = merge({
    "reboot-command" : "/usr/bin/systemctl reboot",
    "pre-reboot-node-labels" : "kured=rebooting",
    "post-reboot-node-labels" : "kured=done",
    "period" : "5m",
  }, var.automatic_updates.kured.options)
}
