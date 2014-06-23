#!/bin/sh
# Cleanup docker files: untagged containers and images.
#
# Use `docker-cleanup -n` for a dry run to see what would be deleted.

untagged_containers() {
  # Print containers using untagged images: $1 is used with awk's print: 0=line, 1=column 1.
  docker ps -a | awk '$2 ~ "[0-9a-f]{12}" {print $'$1'}'
}

untagged_images() {
  # Print untagged images: $1 is used with awk's print: 0=line, 3=column 3.
  # NOTE: intermediate images (via -a) seem to only cause
  # "Error: Conflict, foobarid wasn't deleted" messages.
  # Might be useful sometimes when Docker messed things up?!
  # docker images -a | awk '$1 == "<none>" {print $'$1'}'
  docker images | tail -n +2 | awk '$1 == "<none>" {print $'$1'}'
}

# Dry-run.
if [ "$1" = "-n" ]; then
  echo "=== Containers with uncommitted images: ==="
  untagged_containers 0
  echo

  echo "=== Uncommitted images: ==="
  untagged_images 0

  exit
fi

echo $1 
echo $2 
echo $3 
echo $4
# remove
if [ $1 = "remove" ]; then
  # remove container
  if [ "$2" = "container" ]; then
    # remove all running container
    if [ "$3" = "running" ]; then
      docker rm $(docker stop -t=1 $(docker ps -q))
      echo "Removed all running container."
    fi
    # remove all container
    if [ "$3" = "all" ]; then
      docker rm $(docker ps -a -q)
      echo "Removed all container."
    fi
    # remove all stopped container
    if [ "$3" = "stopped" ]; then
      RUNNING=$(docker ps -q)
      ALL=$(docker ps -a -q)

      for container in $ALL ; do
        [[ "$RUNNING" =~ "$container" ]] && continue
        echo Removing container: $(docker rm $container)
      done
      echo "Removed all stopped container."
    fi
    # remove all container before given container
    if [ "$3" = "before" ]; then
      docker rm $(docker ps --before '$4' -q)
      echo Removed all container before "$4"
    fi
    # remove all container since given container
    if [ "$3" = "since" ]; then
      docker rm $(docker ps --since '$4' -q)
      echo Removed all container since "$4"
    fi
  fi

  if [ "$2" = "images" ]; then
    #remove all images
    if [ "$3" = "all" ]; then
      docker rmi $(docker ps -a -q)
      echo Removed all images.
    fi
    # remove all untagged images
    if [ "$3" = "untagged" ]; then
      untagged_images 3 | xargs --no-run-if-empty docker rmi
      echo Removed all untagged all images. 
    fi
  fi
fi 
