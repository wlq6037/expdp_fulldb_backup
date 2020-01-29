# expdp_fulldb_backup

*The script is backup Oracle database fully by expdp.*

## Platform requirements:     
                          Linux/centos7
                          Oracle database 11g
                          expdp commnad is required
                          It run under oracle user (Oracle database owner)
                          DB information from configure file(default: oradb.conf)
               

## Prerequisites  
1.install sshpass package  
`wget http://www.rpmfind.net/linux/epel/6/x86_64/Packages/s/sshpass-1.06-1.el6.x86_64.rpm`  
`rpm -ivh sshpass-1.06-1.el6.x86_64.rpm`  
2.sftp server  
you should setup sftp server first. add user/passwd so that we can transfer dump files.  

*create by: wlq6037@gmail.com*  
*bug fix contact: wlq6037@163.com*
