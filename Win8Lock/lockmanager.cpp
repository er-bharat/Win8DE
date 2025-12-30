#include "lockmanager.h"
#include <QDebug>
#include <pwd.h>
#include <unistd.h>
#include <security/pam_appl.h>

LockManager::LockManager(QObject *parent)
: QObject(parent)
{
}

QString getCurrentUser() {
    struct passwd *pw = getpwuid(getuid());
    return pw ? QString(pw->pw_name) : QString();
}

static int pam_conversation(int num_msg, const struct pam_message **msg,
                            struct pam_response **resp, void *appdata_ptr)
{
    if (num_msg <= 0)
        return PAM_CONV_ERR;

    struct pam_response *reply = static_cast<struct pam_response *>(calloc(num_msg, sizeof(struct pam_response)));
    if (!reply)
        return PAM_BUF_ERR;

    for (int i = 0; i < num_msg; ++i) {
        if (msg[i]->msg_style == PAM_PROMPT_ECHO_OFF || msg[i]->msg_style == PAM_PROMPT_ECHO_ON) {
            reply[i].resp = strdup(static_cast<const char *>(appdata_ptr));
        } else if (msg[i]->msg_style == PAM_ERROR_MSG || msg[i]->msg_style == PAM_TEXT_INFO) {
            reply[i].resp = nullptr;
        } else {
            free(reply);
            return PAM_CONV_ERR;
        }
    }

    *resp = reply;
    return PAM_SUCCESS;
}

void LockManager::authenticate(const QString & /*qmlUsername*/, const QString &password)
{
    QString username = getCurrentUser();
    qDebug() << "Authenticating as:" << username;

    // Keep the QByteArray alive until after pam_end()
    QByteArray passwordUtf8 = password.toLocal8Bit();

    struct pam_conv conv = { pam_conversation, (void *)passwordUtf8.data() };
    pam_handle_t *pamh = nullptr;

    int ret = pam_start("system-auth", username.toLocal8Bit().constData(), &conv, &pamh);
    if (ret != PAM_SUCCESS) {
        qDebug() << "pam_start failed:" << pam_strerror(pamh, ret);
        emit authResult(false);
        return;
    }

    ret = pam_authenticate(pamh, 0);
    if (ret != PAM_SUCCESS) {
        qDebug() << "pam_authenticate failed:" << pam_strerror(pamh, ret);
        pam_end(pamh, ret);
        emit authResult(false);
        return;
    }

    ret = pam_acct_mgmt(pamh, 0);
    if (ret != PAM_SUCCESS) {
        qDebug() << "pam_acct_mgmt failed:" << pam_strerror(pamh, ret);
        pam_end(pamh, ret);
        emit authResult(false);
        return;
    }

    pam_end(pamh, PAM_SUCCESS);
    emit authResult(true);
}

