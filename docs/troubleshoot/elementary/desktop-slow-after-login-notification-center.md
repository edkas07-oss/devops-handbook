# Desktop Slow After Login Due to Notification Center

## Overview

After updating Elementary OS, the desktop becomes very slow immediately after login. The mouse can still move and applications remain running, but switching focus between windows becomes difficult and the desktop feels unresponsive.

Investigation showed that the issue was caused by **Wingpanel Notification Center** processing a very large backlog of notifications from **WhatsApp Web**.

---

## Symptoms

- Desktop becomes very slow after login.
- Unable to activate windows running in the background.
- Mouse remains responsive.
- Keyboard shortcuts still work.
- Terminal can still be opened.
- High CPU utilization by `io.elementary.wingpanel`.

Example:

```bash
ps -eo pid,%cpu,%mem,cmd --sort=-%cpu | head
```

Example output:

```text
PID %CPU CMD
4982 24.6 io.elementary.wingpanel
4937  6.2 /usr/bin/gala
```

---

## Root Cause

Wingpanel Notification Center attempts to restore all previous notifications during login.

Most notifications originated from **WhatsApp Web** running in Google Chrome.

Each notification referenced a temporary icon stored under:

```text
/tmp/com.google.Chrome.scoped_dir.*/icon.png
```

Since the `/tmp` directory is cleared after reboot, those icons no longer exist. Wingpanel repeatedly tries to load the missing icons, generating thousands of errors and causing high CPU utilization.

Example:

```text
NotificationEntry.vala:79:
Unable to mask image:
Failed to open file "/tmp/com.google.Chrome.scoped_dir.xxxxxx/icon.png"
```

---

# Resolution

## ① Verify the Symptoms

*Confirm that the issue matches this known problem.*

Check Wingpanel CPU utilization.

```bash
ps -eo pid,%cpu,%mem,cmd --sort=-%cpu | head
```

Expected problematic output:

```text
io.elementary.wingpanel 20%+
```

Review notification errors.

```bash
journalctl --user | grep -i notification | tail -50
```

Look for repeated messages similar to:

```text
NotificationEntry.vala:79:
Unable to mask image
```

---

## ② Disable Website Notifications in Chrome

*Stop the notification source.*

1. Open **Google Chrome**.
2. Navigate to:

    ```text
    chrome://settings/content/notifications
    ```

3. Locate the website generating excessive notifications.
4. Click **⋮** → **Block** or **Remove**.

In this case:

```text
https://web.whatsapp.com
```

!!! tip

    If browser notifications are not required, disable website notifications completely by selecting **Don't allow sites to send notifications**.

---

## ③ Clear Notification Center Cache

*Remove accumulated notification data.*

Stop Wingpanel and Notification Service.

```bash
killall io.elementary.wingpanel
killall io.elementary.notifications
```

Remove the notification cache.

```bash
rm -rf ~/.cache/io.elementary.notifications
```

Log out and log back in.

!!! note

    If the desktop immediately becomes responsive after stopping Wingpanel,
    the Notification Center is likely the root cause.

---

## ④ Verify the Resolution

*Confirm the issue has been resolved.*

Check CPU usage again.

```bash
ps -eo pid,%cpu,%mem,cmd --sort=-%cpu | head
```

Expected result:

```text
io.elementary.wingpanel < 1%
```

Verify that notification errors no longer appear.

```bash
journalctl --user | grep -i notification
```

No repeated errors similar to:

```text
NotificationEntry.vala:79
Unable to mask image
```

Finally, reboot the system and verify that:

- Desktop loads normally.
- Windows can be selected without delay.
- Wingpanel CPU remains low.

---

## Lessons Learned

- The issue was **not** caused by:
    - Linux Kernel
    - NVIDIA Driver
    - Gala Window Manager
    - X11

- The root cause was **Wingpanel Notification Center** processing thousands of stale Chrome notifications.

- WhatsApp Web notifications can accumulate over time and significantly impact desktop responsiveness after reboot.

---

## References

Check CPU Usage

```bash
ps -eo pid,%cpu,%mem,cmd --sort=-%cpu | head
```

Check Notification Errors

```bash
journalctl --user | grep -i notification
```

Stop Notification Services

```bash
killall io.elementary.wingpanel
killall io.elementary.notifications
```

Clear Notification Cache

```bash
rm -rf ~/.cache/io.elementary.notifications
```

Google Chrome Notification Settings

```text
chrome://settings/content/notifications
```