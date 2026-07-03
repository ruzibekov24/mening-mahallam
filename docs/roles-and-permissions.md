# Roles & Permissions

Version: v0.0.6

Status: Approved

Last Updated: July 3, 2026

---

# Purpose

This document defines the roles available in Mahallam and the permissions assigned to each role.

The goal is to keep the platform secure while ensuring each user has access only to the features they need.

---

# Roles

## 👤 Resident

A verified resident of a mahalla.

### Permissions

✅ View announcements

✅ View events

✅ Receive notifications

✅ Create reports

✅ Comment on announcements

✅ Edit own profile

❌ Create announcements

❌ Delete other users' content

❌ Moderate comments

❌ Manage users

---

## 🏛️ Mahalla Administrator

Official representative of a specific mahalla.

### Permissions

✅ Everything Resident can do

✅ Create announcements

✅ Edit own announcements

✅ Delete own announcements

✅ Create events

✅ Respond to reports

✅ View all reports in their mahalla

✅ Approve resident verification requests

❌ Manage other mahallas

❌ Access system settings

---

## 🛡️ Moderator

Responsible for keeping the community clean.

### Permissions

✅ Everything Resident can do

✅ Remove spam

✅ Remove inappropriate comments

✅ Hide inappropriate reports

✅ Temporarily suspend users

❌ Create official announcements

❌ Manage platform settings

---

## 👑 Super Admin

Platform owner.

### Permissions

✅ Full access

- Manage every mahalla
- Manage moderators
- Manage administrators
- View analytics
- Manage platform settings
- Broadcast national announcements
- Suspend any account
- Restore deleted content

---

# Permission Matrix

| Feature | Resident | Admin | Moderator | Super Admin |
|----------|----------|-------|------------|-------------|
| View Announcements | ✅ | ✅ | ✅ | ✅ |
| Create Announcement | ❌ | ✅ | ❌ | ✅ |
| Create Report | ✅ | ✅ | ✅ | ✅ |
| Comment | ✅ | ✅ | ✅ | ✅ |
| Moderate Comments | ❌ | ❌ | ✅ | ✅ |
| Approve Residents | ❌ | ✅ | ❌ | ✅ |
| Manage Mahalla | ❌ | ✅ (Own only) | ❌ | ✅ |
| Manage Platform | ❌ | ❌ | ❌ | ✅ |

---

# Principle

Permissions should always follow the principle of least privilege.

Users receive only the permissions required for their role.
