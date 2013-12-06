#include "mainwindow.h"
#include <QApplication>
#include <QMessageBox>
#include <QDebug>
#include "pcbsd-ui.h"
#include "jailsbackend.h"

#include <unistd.h>
#include <sys/types.h>

int main(int argc, char *argv[])
{
    PCSingleApplication a(argc, argv);

    MainWindow w;

    QObject::connect(&a, SIGNAL(messageReceived(const QString &)), &w, SLOT(slotSingleInstance()));

    bool is_warden_found= false;
    QString jail_name;
    for (int i=1; i<argc; i++)
    {
        QString arg = argv[i];
        if (arg.trimmed() == "-jail")
        {
            is_warden_found= true;
            continue;
        }
        if (is_warden_found)
        {
            jail_name= arg;
            break;
        }
    }//for all args
    if (jail_name.length())
    {
        CJailsBackend jail;
        jail.setJail(jail_name);
        jail.setJailEnabled(true);
        qDebug()<<"JAIL";
        w.setJail(jail);
    }

    w.show();

    //Check for root
    if (0 != geteuid())
    {
        QMessageBox msg;
        msg.setText(w.tr("You should run this application as root"));
        msg.exec();
        exit(2);
    }
    
    return a.exec();
}
