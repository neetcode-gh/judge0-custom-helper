FROM judge0/judge0:1.12.0

ENV EIGEN_VERSION 3.3.8
RUN set -xe && \
    curl -fSsL "https://gitlab.com/libeigen/eigen/-/archive/$EIGEN_VERSION/eigen-$EIGEN_VERSION.zip" -o /tmp/eigen.zip && \
    unzip /tmp/eigen.zip -d /tmp && \
    mv /tmp/eigen-$EIGEN_VERSION/Eigen /usr/include && \
    rm -rf /tmp/*