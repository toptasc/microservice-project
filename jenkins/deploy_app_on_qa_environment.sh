echo 'Deploying App on Kubernetes'
envsubst < k8s/petclinic_chart/values-template.yaml > k8s/petclinic_chart/values.yaml
sed -i s/HELM_VERSION/${BUILD_NUMBER}/ k8s/petclinic_chart/Chart.yaml
AWS_REGION=$AWS_REGION helm repo add stable-petclinic s3://petclinic-helm-charts-toptas/stable/myapp/ || echo "repository name already exists"
AWS_REGION=$AWS_REGION helm repo update
helm package k8s/petclinic_chart
AWS_REGION=$AWS_REGION helm s3 push --force petclinic_chart-${BUILD_NUMBER}.tgz stable-petclinic
kubectl create ns petclinic-qa || echo "namespace petclinic-qa already exists"
kubectl delete secret regcred -n petclinic-qa || echo "there is no regcred secret in petclinic-qa namespace"
kubectl create secret generic regcred -n petclinic-qa \
    --from-file=.dockerconfigjson=/var/lib/jenkins/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
AWS_REGION=$AWS_REGION helm repo update
AWS_REGION=$AWS_REGION helm upgrade --install \
    petclinic-app-release stable-petclinic/petclinic_chart --version ${BUILD_NUMBER} \
    --namespace petclinic-qa
# s3 bucket name'i değiştir.
# AWS_REGION=$AWS_REGION helm s3 push --force --->> force komutu aynı repo varsa yine de oluştur demek.
# envsubst < k8s/petclini.... --->> devops müh. olarak amacımız, olayı otomatik hale getirmek ve isimleri dinamik olarak almaktır. peki biz k8s/template klasörünün altında neden values.yaml varken ayıca values-template.yaml dosyası oluşturduk. her seferinde testi çalıştırdığımızda, isimleri tag'e göre alacağı için değiştirecektir. burada envsubst komutu yerine sed, awk komutları da kullanılabilirdi. biz burada envsubst kullanarak aslında values-template.yaml içinde $ işareti ile belirlenen tüm env.var.ları içinde bulunduğu shell'e bakıyor, bunları env.var. ile dğeiştiriyor. böylece asıl kullanacağımız values.yaml dosyası oluşmuş oluyor. yani aslında values.yaml dosyası yok gibi  varsayacağız, her defasında yeniden oluşturuyoruz veya üzerine overwrite ediyoruz.
# kısaca dosyayı çalıştırdığımızda values-template.yaml dosyası değişmesin values.yaml değişsin istiyoruz. çünkü template altındaki manifesto dosyalarımız değilkenleri values.yaml'dan alacak. 
# sed -i s/HELM_VERSION/${BUILD_NUMBER} --->> sed komutu ile chart.yaml'ı değiştiriyoruz. yani chart.yaml içinde gördüğün HELM_VERSIon gördüğün yere sed komutu ile ${BUILD_NUMBER} yaz diyoruz. BUILD_NUMBER da jenkins job'tan geliyor. her job çalıştırıldığında farklı bir job numarası alacak. 
# kubectl create secret generic regcred -n petclinic-qa \ --->> burada regestration credential neden oluşturuyoruz? petclinic-chart/template altındaki manifesto dosyalarının aşağıdaki gibi yaptığım için yani private repodan çektiğim için burada regcred kullanıyorum. public repo oluştursaydım gerek kalmazdı bu bloğu yazmama.
     