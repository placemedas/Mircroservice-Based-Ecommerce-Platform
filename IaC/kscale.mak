#
# Use this make file to scale up or down the number of pod replicas for each deployment

KC=kubectl
APP_NS=c756ns

all: 
	$(KC) autoscale -n $(APP_NS) deployment cyberdb --min=2 --max=10
	$(KC) autoscale -n $(APP_NS) deployment product --min=2 --max=10
	$(KC) autoscale -n $(APP_NS) deployment cart --min=2 --max=10
	$(KC) autoscale -n $(APP_NS) deployment customer --min=2 --max=10
	$(KC) autoscale -n $(APP_NS) deployment logger --min=2 --max=10

delete: 
	$(KC) delete -n $(APP_NS) hpa cyberdb product cart customer logger


