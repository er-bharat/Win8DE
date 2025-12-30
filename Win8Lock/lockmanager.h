#pragma once

#include <QObject>

class LockManager : public QObject
{
    Q_OBJECT
public:
    explicit LockManager(QObject *parent = nullptr);

    Q_INVOKABLE void authenticate(const QString &username, const QString &password);

signals:
    void authResult(bool success);
};
